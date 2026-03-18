<script lang="ts">
	import { base } from '$app/paths';
	import { dashboard, states, currentViewId, motion, editMode } from '$lib/Stores';
	import Icon from '@iconify/svelte';
	import type { FooterDockItem } from '$lib/Types';

	$: items = ($dashboard?.footer?.items || []).filter(Boolean) as FooterDockItem[];

	function openUrl(url: string) {
		if (!url) return;
		if (url.startsWith('/') || url.startsWith('http')) {
			window.open(url.startsWith('http') ? url : `${base}${url}`, '_blank', 'noopener');
		} else {
			window.open(url, '_blank', 'noopener');
		}
	}

	function switchView(name: string) {
		const n = name.trim().toLowerCase();
		const v = $dashboard?.views?.find(
			(x) => (x.name || '').toLowerCase().includes(n) || n.includes((x.name || '').toLowerCase())
		);
		if (v?.id != null) $currentViewId = v.id;
	}

	function badgeFor(item: FooterDockItem): string | null {
		const id = item.badge_entity;
		if (!id || !$states?.[id]) return null;
		const s = $states[id].state;
		if (s === 'unknown' || s === 'unavailable') return null;
		return String(s);
	}

	function click(item: FooterDockItem) {
		if ($editMode) return;
		if (item.view) switchView(item.view);
		else if (item.url) openUrl(item.url);
	}
</script>

{#if items.length}
	<nav class="dock" aria-label="Footer shortcuts">
		{#each items as item}
			{@const badge = badgeFor(item)}
			<button
				type="button"
				class="item"
				disabled={$editMode && !item.url}
				on:click={() => click(item)}
				title={item.label}
			>
				{#if item.icon}
					<span class="ico">
						<Icon icon={item.icon} height={22} />
					</span>
				{/if}
				<span class="lab">{item.label}</span>
				{#if badge != null && badge !== '0' && badge !== 'off'}
					<span class="badge">{badge}</span>
				{/if}
			</button>
		{/each}
	</nav>
{/if}

<style>
	.dock {
		grid-area: dock;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: center;
		gap: 0.35rem 0.5rem;
		padding: 0.5rem 0.75rem calc(0.5rem + env(safe-area-inset-bottom, 0));
		background: rgba(0, 0, 0, 0.22);
		border-top: 1px solid rgba(58, 69, 73, 0.35);
		backdrop-filter: blur(8px);
	}

	.item {
		position: relative;
		display: inline-flex;
		flex-direction: column;
		align-items: center;
		gap: 0.15rem;
		min-width: 3.25rem;
		padding: 0.35rem 0.5rem;
		border: none;
		border-radius: 0.45rem;
		background: rgba(34, 38, 39, 0.65);
		color: var(--theme-colors-text, rgba(255, 255, 255, 0.88));
		font-size: 0.65rem;
		font-weight: 500;
		cursor: pointer;
		transition: background 0.15s ease, transform 0.12s ease;
	}

	.item:hover:not(:disabled) {
		background: rgba(52, 57, 58, 0.85);
	}

	.item:disabled {
		opacity: 0.5;
		cursor: default;
	}

	.ico {
		display: flex;
		opacity: 0.92;
	}

	.lab {
		max-width: 4.5rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.badge {
		position: absolute;
		top: 0.15rem;
		right: 0.2rem;
		min-width: 1rem;
		height: 1rem;
		padding: 0 0.28rem;
		font-size: 0.6rem;
		font-weight: 700;
		line-height: 1rem;
		text-align: center;
		border-radius: 999px;
		background: #c62828;
		color: #fff;
	}
</style>
