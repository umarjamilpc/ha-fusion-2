<script lang="ts">
	import { dashboard, lang, record, ripple } from '$lib/Stores';
	import { onDestroy } from 'svelte';
	import ContextHero from '$lib/Sidebar/ContextHero.svelte';
	import ConfigButtons from '$lib/Modal/ConfigButtons.svelte';
	import Modal from '$lib/Modal/Index.svelte';
	import Ripple from 'svelte-ripple';
	import { updateObj } from '$lib/Utils';
	import type { ContextHeroItem } from '$lib/Types';

	export let isOpen: boolean;
	export let sel: ContextHeroItem;

	let entityText =
		(sel?.summary_entities || []).join('\n') || '';
	let weatherVal = '';

	$: if (sel && isOpen) {
		entityText = (sel.summary_entities || []).join('\n');
		weatherVal = sel.weather_entity || '';
	}

	function set(key: string, event?: any) {
		sel = updateObj(sel, key, event);
		$dashboard = $dashboard;
	}

	function syncEntities() {
		const lines = entityText
			.split(/[\n,]+/)
			.map((s) => s.trim())
			.filter(Boolean);
		sel.summary_entities = lines.length ? lines : undefined;
		$dashboard = $dashboard;
	}

	function onWeatherBlur() {
		const v = weatherVal.trim();
		if (v) sel.weather_entity = v;
		else delete sel.weather_entity;
		$dashboard = $dashboard;
	}

	onDestroy(() => {
		syncEntities();
		$record();
	});
</script>

{#if isOpen}
	<Modal size="large">
		<h1 slot="title">{$lang('context_hero')}</h1>

		<p class="hint">
			{$lang('context_hero_hint')}
		</p>

		<h2>{$lang('preview')}</h2>
		<div class="preview">
			<ContextHero {sel} demo={!entityText.trim()} />
		</div>

		<h2>{$lang('context_hero_entities')}</h2>
		<textarea
			class="entities"
			rows="6"
			placeholder="light.living_room&#10;switch.tv&#10;fan.bedroom"
			bind:value={entityText}
			on:blur={syncEntities}
		/>

		<h2>{$lang('weather')}</h2>
		<input
			class="input"
			type="text"
			placeholder="weather.home"
			bind:value={weatherVal}
			on:blur={onWeatherBlur}
		/>

		<h2>{$lang('time_format_header')}</h2>
		<div class="button-container">
			<button
				class:selected={!sel?.hour12}
				on:click={() => set('hour12', false)}
				use:Ripple={$ripple}
			>
				{$lang('time_format_24')}
			</button>
			<button
				class:selected={sel?.hour12 !== false}
				on:click={() => set('hour12', true)}
				use:Ripple={$ripple}
			>
				{$lang('time_format_12')}
			</button>
		</div>

		<h2>{$lang('seconds')}</h2>
		<div class="button-container">
			<button
				class:selected={!sel?.seconds}
				on:click={() => set('seconds', false)}
				use:Ripple={$ripple}
			>
				{$lang('no')}
			</button>
			<button
				class:selected={sel?.seconds}
				on:click={() => set('seconds', true)}
				use:Ripple={$ripple}
			>
				{$lang('yes')}
			</button>
		</div>

		<h2>{$lang('mobile')}</h2>
		<div class="button-container">
			<button
				class:selected={sel?.hide_mobile !== true}
				on:click={() => set('hide_mobile')}
				use:Ripple={$ripple}
			>
				{$lang('visible')}
			</button>
			<button
				class:selected={sel?.hide_mobile === true}
				on:click={() => set('hide_mobile', true)}
				use:Ripple={$ripple}
			>
				{$lang('hidden')}
			</button>
		</div>

		<ConfigButtons {sel} />
	</Modal>
{/if}

<style>
	.hint {
		opacity: 0.75;
		font-size: 0.9rem;
		line-height: 1.45;
		margin: 0 0 1rem 0;
	}

	.preview {
		padding: 0.5rem 0;
		border-radius: 0.5rem;
		background: var(--theme-colors-sidebar-background, rgba(0, 0, 0, 0.08));
	}

	.entities {
		width: 100%;
		font-family: ui-monospace, monospace;
		font-size: 0.85rem;
		padding: 0.65rem;
		border-radius: 0.4rem;
		border: 1px solid rgba(128, 128, 128, 0.25);
		background: var(--theme-modal-background, #1a1a1a);
		color: inherit;
		resize: vertical;
	}

	.input {
		width: 100%;
		padding: 0.5rem 0.65rem;
		border-radius: 0.4rem;
		border: 1px solid rgba(128, 128, 128, 0.25);
		background: var(--theme-modal-background, #1a1a1a);
		color: inherit;
	}

	.button-container {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		margin-bottom: 0.75rem;
	}

	.button-container button {
		padding: 0.45rem 0.85rem;
		border-radius: 0.35rem;
		border: 1px solid rgba(128, 128, 128, 0.3);
		background: transparent;
		cursor: pointer;
		color: inherit;
	}

	.button-container button.selected {
		border-color: var(--theme-colors-primary, #3182b7);
		background: rgba(49, 130, 183, 0.15);
	}

	h2 {
		font-size: 0.95rem;
		margin: 1rem 0 0.4rem 0;
		opacity: 0.9;
	}
</style>
