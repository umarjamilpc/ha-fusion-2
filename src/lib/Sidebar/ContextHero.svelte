<script lang="ts">
	import { timer, selectedLanguage, states, onStates, lang } from '$lib/Stores';
	import type { ContextHeroItem } from '$lib/Types';

	export let sel: ContextHeroItem;
	export let demo = false;

	$: hour12 = sel?.hour12 !== false;
	$: seconds = sel?.seconds === true;

	$: timeStr = $timer.toLocaleTimeString($selectedLanguage || 'en', {
		hour: hour12 ? 'numeric' : '2-digit',
		minute: '2-digit',
		second: seconds ? '2-digit' : undefined,
		hour12: hour12
	});

	$: dateStr = $timer.toLocaleDateString($selectedLanguage || 'en', {
		weekday: 'long',
		day: 'numeric',
		month: 'long'
	});

	$: h = $timer.getHours();
	$: greet =
		h <= 4
			? $lang('greet_night') !== 'greet_night'
				? $lang('greet_night')
				: 'Good night'
			: h <= 10
				? $lang('greet_morning') !== 'greet_morning'
					? $lang('greet_morning')
					: 'Good morning'
				: h <= 16
					? $lang('greet_day') !== 'greet_day'
						? $lang('greet_day')
						: 'Good afternoon'
					: $lang('greet_evening') !== 'greet_evening'
						? $lang('greet_evening')
						: 'Good evening';

	function buildSummary(ids: string[] | undefined): string {
		if (demo) return '6 lights, Computer, Fan and TV are on';
		if (!ids?.length) return '';

		const lightsOn: string[] = [];
		const otherOn: string[] = [];
		const on = $onStates as string[];

		for (const id of ids) {
			const e = $states?.[id];
			if (!e) continue;
			const st = (e.state || '').toLowerCase();
			if (!on.includes(st) && st !== 'playing' && st !== 'home') continue;
			const name = e.attributes?.friendly_name || id.split('.').pop() || id;
			if (id.startsWith('light.')) lightsOn.push(name);
			else otherOn.push(name);
		}

		if (!lightsOn.length && !otherOn.length) {
			const all = $lang('summary_all_off');
			return all !== 'summary_all_off' ? all : 'Everything is off';
		}

		const L = lightsOn.length;
		const O = otherOn.length;
		const oJoin = (arr: string[]) =>
			arr.length <= 1 ? arr[0] : arr.slice(0, -1).join(', ') + ' and ' + arr[arr.length - 1];

		if (L > 1 && O === 0) return `${L} lights on`;
		if (L === 1 && O === 0) return `${lightsOn[0]} is on`;
		if (L === 0 && O > 0) return `${oJoin(otherOn)} on`;
		if (L === 1 && O === 1) return `${lightsOn[0]} and ${otherOn[0]} on`;
		if (L > 1 && O >= 1)
			return `${L} lights, ${oJoin(otherOn)} on`;
		if (L === 1 && O > 1) return `${lightsOn[0]}, ${oJoin(otherOn)} on`;
		return `${L} lights on`;
	}

	$: summaryLine = buildSummary(sel?.summary_entities);

	$: weatherLine = (() => {
		if (demo) return 'Feels like 23° — no rain expected';
		const wid = sel?.weather_entity;
		if (!wid || !$states?.[wid]) return '';
		const e = $states[wid];
		const t = e.attributes?.temperature;
		if (t == null) return '';
		const cond = e.state || '';
		return `${Math.round(Number(t))}° · ${cond.replace(/-/g, ' ')}`;
	})();
</script>

<div class="hero" class:demo>
	<div class="time">{timeStr}</div>
	<div class="date">{dateStr}</div>
	<div class="greet">{greet} 👋</div>
	{#if summaryLine}
		<p class="summary">{summaryLine}</p>
	{/if}
	{#if weatherLine}
		<p class="weather">{weatherLine}</p>
	{/if}
</div>

<style>
	.hero {
		padding: 0.5rem 1rem 1rem 1rem;
		display: flex;
		flex-direction: column;
		gap: 0.15rem;
	}

	.time {
		font-size: var(--theme-sizes-sidebar-time, clamp(2.25rem, 5vw, 3.5rem));
		font-weight: 600;
		line-height: 1.05;
		letter-spacing: -0.03em;
		text-shadow: 0 1px 12px rgba(0, 0, 0, 0.25);
	}

	.date {
		font-size: 1.05rem;
		font-weight: 500;
		opacity: 0.82;
		margin-top: 0.15rem;
		text-transform: capitalize;
	}

	.greet {
		font-size: 1.15rem;
		font-weight: 600;
		margin-top: 0.65rem;
		opacity: 0.95;
	}

	.summary,
	.weather {
		margin: 0.5rem 0 0 0;
		font-size: 0.88rem;
		line-height: 1.45;
		opacity: 0.78;
		font-weight: 450;
		max-width: 22rem;
	}

	.demo .summary,
	.demo .weather {
		opacity: 0.85;
	}
</style>
