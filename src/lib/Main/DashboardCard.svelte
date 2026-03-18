<script lang="ts">
	import { spring } from 'svelte/motion';
	import { onDestroy, onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import { cubicOut } from 'svelte/easing';
	import Ripple from 'svelte-ripple';

	/** Entity / control visually “on” → bloom + stronger glass */
	export let active = false;
	export let editMode = false;
	/** RGB or any CSS color for active glow */
	export let glowColor = 'rgb(75, 166, 237)';
	export let rippleOptions: Record<string, unknown> | null = null;
	export let minHeight = '3.85rem';
	/** Secondary line: temperature, fan %, etc. */
	export let sublabel: string | undefined = undefined;

	let reduceMotion = false;
	let mounted = false;

	const scale = spring(1, { stiffness: 0.28, damping: 0.36 });

	onMount(() => {
		mounted = true;
		reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
		const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
		const handler = () => {
			reduceMotion = mq.matches;
		};
		mq.addEventListener('change', handler);
		return () => mq.removeEventListener('change', handler);
	});

	function pressDown() {
		if (editMode || reduceMotion || !mounted) return;
		scale.set(0.96);
	}

	function pressUp() {
		scale.set(1);
	}

	onDestroy(() => scale.set(1));

	$: glowRgb = parseGlow(glowColor);
	$: ripple =
		rippleOptions ??
		({
			color: 'rgba(0,0,0,0)',
			opacity: 0
		} as Record<string, unknown>);

	function parseGlow(c: string): { r: number; g: number; b: number } {
		const m = c?.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i);
		if (m) return { r: +m[1], g: +m[2], b: +m[3] };
		return { r: 75, g: 166, b: 237 };
	}
</script>

<div
	class="dashboard-card-press font-sans"
	style:transform="scale({$scale})"
	style:will-change="transform"
	on:pointerdown={pressDown}
	on:pointerup={pressUp}
	on:pointercancel={pressUp}
	on:pointerleave={pressUp}
>
	<div
		class="dashboard-card-surface relative min-w-0 overflow-hidden rounded-glass border font-sans transition-[box-shadow,background-color,border-color] duration-glass ease-out"
		class:dashboard-card-active={active}
		style:min-height={minHeight}
		style:--glow-r={glowRgb.r}
		style:--glow-g={glowRgb.g}
		style:--glow-b={glowRgb.b}
		use:Ripple={ripple}
	>
		{#if active}
			<div
				class="pointer-events-none absolute inset-0 rounded-glass opacity-90"
				in:fade={{ duration: reduceMotion ? 0 : 280, easing: cubicOut }}
				out:fade={{ duration: reduceMotion ? 0 : 180 }}
				style="background: radial-gradient(
					120% 80% at 18% 22%,
					rgba(var(--glow-r), var(--glow-g), var(--glow-b), 0.22) 0%,
					transparent 55%
				);"
			/>
		{/if}

		<div
			class="relative z-[1] flex h-full min-h-[inherit] w-full items-center gap-3 px-3 py-2.5"
		>
			<div class="icon-slot flex shrink-0 items-center justify-center">
				<slot name="icon" />
			</div>
			<div class="flex min-w-0 flex-1 flex-col justify-center gap-0.5 overflow-hidden">
				<slot />
				{#if sublabel}
					<div
						class="sublabel-slot text-[0.72rem] font-medium leading-tight tracking-wide text-white/45"
					>
						{sublabel}
					</div>
				{/if}
			</div>
		</div>
	</div>
</div>

<style>
	.dashboard-card-surface {
		background: var(--glass-bg, rgba(255, 255, 255, 0.055));
		border-color: var(--glass-border, rgba(255, 255, 255, 0.11));
		box-shadow: var(--glass-shadow, 0 4px 24px rgba(0, 0, 0, 0.28));
		backdrop-filter: blur(var(--glass-blur, 22px));
		-webkit-backdrop-filter: blur(var(--glass-blur, 22px));
	}

	.dashboard-card-active {
		border-color: rgba(255, 255, 255, 0.18);
		background: rgba(255, 255, 255, 0.08);
		box-shadow:
			var(--glass-shadow, 0 4px 24px rgba(0, 0, 0, 0.28)),
			0 0 0 1px rgba(255, 255, 255, 0.06),
			0 0 42px -6px rgba(var(--glow-r), var(--glow-g), var(--glow-b), 0.45);
	}

	.dashboard-card-press {
		transform-origin: center center;
		width: 100%;
		height: 100%;
	}

	:global(.dashboard-card-active) .sublabel-slot {
		color: rgba(255, 255, 255, 0.5);
	}
</style>
