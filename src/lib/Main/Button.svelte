<script lang="ts">
	import ComputeIcon from '$lib/Components/ComputeIcon.svelte';
	import StateLogic from '$lib/Components/StateLogic.svelte';
	import {
		connection,
		editMode,
		itemHeight,
		lang,
		motion,
		onStates,
		climateHvacActionToMode,
		ripple,
		states,
		templates,
		config,
		selectedLanguage,
		calendarView,
		calendarFirstDay
	} from '$lib/Stores';
	import { getDomain, getName, getTogglableService } from '$lib/Utils';
	import Icon, { loadIcon } from '@iconify/svelte';
	import { callService, type HassEntity } from 'home-assistant-js-websocket';
	import { marked } from 'marked';
	import { onDestroy } from 'svelte';
	import { openModal } from 'svelte-modals';
	import parser from 'js-yaml';
	import DashboardCard from '$lib/Main/DashboardCard.svelte';

	export let demo: string | undefined = undefined;
	export let sel: any;
	export let sectionName: string | undefined = undefined;

	$: entity_id = demo || sel?.entity_id;
	$: template = $templates?.[sel?.id];
	$: icon = (sel?.template?.icon && template?.icon?.output) || sel?.icon;
	$: color = (sel?.template?.color && template?.color?.output) || sel?.color;
	$: marquee = sel?.marquee;
	$: more_info = sel?.more_info;

	let entity: HassEntity;
	let contentWidth: number;
	let container: HTMLDivElement;
	let loading: boolean;
	let resetLoading: ReturnType<typeof setTimeout> | null;
	let stateOn: boolean;

	/** display loader if no state change has occurred within `$motion`ms */
	let delayLoading: ReturnType<typeof setTimeout> | null;

	/**
	 * Observes changes in the `last_updated` property of an entity.
	 * When the `last_updated` property changes:
	 *
	 * - Updates `entity` with the new state from `$states`
	 * - Resets the `loading` state to `false`
	 * - Clears any pending loading or reset timeouts
	 */
	$: if (entity_id && $states?.[entity_id]?.last_updated !== entity?.last_updated) {
		entity = $states?.[entity_id];

		loading = false;

		if (delayLoading) {
			clearTimeout(delayLoading);
			delayLoading = null;
		}

		if (resetLoading) {
			clearTimeout(resetLoading);
			resetLoading = null;
		}
	}

	$: attributes = entity?.attributes;

	$: iconColor = color
		? color
		: attributes?.hs_color
			? `hsl(${attributes?.hs_color}%, 50%)`
			: 'rgb(75, 166, 237)';

	// icon is image if extension, e.g. test.png
	$: image = icon?.includes('.');

	$: if (sel?.template?.set_state && template?.set_state?.output) {
		// template
		stateOn = $onStates?.includes(template?.set_state?.output?.toLocaleLowerCase());
	} else if (attributes?.hvac_action) {
		// climate
		stateOn = $onStates?.includes(
			$climateHvacActionToMode?.[attributes?.hvac_action]?.toLocaleLowerCase()
		);
	} else if (attributes?.in_progress) {
		// update
		stateOn = typeof attributes.in_progress === 'number';
	} else {
		// default
		stateOn = $onStates?.includes(entity?.state?.toLocaleLowerCase());
	}

	$: sublabel = (() => {
		if (!entity_id || !attributes) return undefined;
		const d = getDomain(entity_id);
		if (
			(d === 'climate' || d === 'water_heater') &&
			attributes.current_temperature != null
		) {
			const u = attributes.temperature_unit || attributes.unit_of_measurement || '';
			return u ? `${attributes.current_temperature} ${u}` : String(attributes.current_temperature);
		}
		if (d === 'humidifier' && attributes.humidity != null) {
			return `${attributes.humidity}%`;
		}
		return undefined;
	})();

	/** Large square / icon-first tiles (matches dashboard.yaml shape + icon_size + height) */
	$: isTile =
		sel?.shape === 'square' ||
		Boolean(
			sel?.icon_size && sel?.height && /px/i.test(String(sel.height))
		);
	$: cardMinHeight =
		isTile && sel?.height?.trim()
			? sel.height.trim()
			: isTile
				? '7.5rem'
				: `${$itemHeight}px`;
	$: iconSizeVar = sel?.icon_size?.trim() || '';

	/**
	 * Toggles the state of the specified entity
	 * using the correct service call...
	 */
	function toggle() {
		// if service template
		if (sel?.template?.service && template?.service?.output) {
			try {
				// template is string, try to parse it
				const _template = parser.load(template?.service?.output) as {
					service: string;
					data: Record<string, string | number | boolean>;
				};

				if (_template?.service) {
					const [domain, service] = _template.service.split('.');
					callService($connection, domain, service, _template?.data);
				}
			} catch (error) {
				console.error('Template service YAML parse error:', error);
			}

			return;
		}

		// default
		const service = getTogglableService(entity);

		if (service) {
			// use returned domain to handle specific cases such
			// as 'remote', which uses 'homeassistant.toggle'
			const [_domain, _service] = service.split('.');
			callService($connection, _domain, _service, {
				entity_id
			});

			// loader
			delayLoading = setTimeout(() => {
				loading = true;
			}, $motion);

			// loader 20s fallback
			resetLoading = setTimeout(() => {
				loading = false;
			}, 20_000);
		} else {
			// not in getTogglableService just open modal
			handleClickEvent();
		}
	}

	/**
	 * Delegate to handleEvent
	 */
	function handlePointer() {
		handleEvent({ type: 'preload' });
	}

	/**
	 * handleEvent
	 * pointerenter | pointerdown | click
	 */
	async function handleEvent(event: any) {
		if (event.type === 'click') {
			await handleClickEvent();
		} else {
			await handlePointerEvent();
		}
	}

	/**
	 * Handle click events
	 * Opens modal for specified domain
	 */
	async function handleClickEvent() {
		if ($editMode) {
			openModal(() => import('$lib/Modal/ButtonConfig.svelte'), {
				demo: entity_id,
				sel,
				sectionName
			});
		} else if (more_info === false) {
			toggle();
		} else {
			switch (getDomain(sel?.entity_id)) {
				// light
				case 'light':
					openModal(() => import('$lib/Modal/LightModal.svelte'), {
						sel: sel
					});
					break;

				// switch
				case 'input_boolean':
				case 'remote':
				case 'siren':
				case 'switch':
					openModal(() => import('$lib/Modal/SwitchModal.svelte'), { sel });
					break;

				// script
				case 'script':
					openModal(() => import('$lib/Modal/ScriptModal.svelte'), { sel });
					break;

				// automation
				case 'automation':
					openModal(() => import('$lib/Modal/AutomationModal.svelte'), { sel });
					break;

				// calendar
				case 'calendar': {
					// set first day of week
					$calendarFirstDay =
						'weekInfo' in Intl.Locale.prototype
							? (new Intl.Locale($selectedLanguage) as any)?.weekInfo.firstDay
							: (await import('weekstart')).getWeekStartByLocale($selectedLanguage);

					// set calendar view type
					$calendarView = localStorage.getItem('calendar');

					openModal(() => import('$lib/Modal/CalendarModal.svelte'), { sel });
					break;
				}

				// sensor
				case 'air_quality':
				case 'date':
				case 'time':
				case 'event':
				case 'image_processing':
				case 'mailbox':
				case 'sensor':
				case 'binary_sensor':
				case 'stt':
				case 'weather':
				case 'button':
				case 'scene':
				case 'schedule':
				case 'sun':
				case 'person':
				case 'zone':
				case 'input_button':
					openModal(() => import('$lib/Modal/SensorModal.svelte'), { sel });
					break;

				// update
				case 'update':
					openModal(() => import('$lib/Modal/UpdateModal.svelte'), { sel });
					break;

				// number
				case 'input_number':
				case 'number':
					openModal(() => import('$lib/Modal/InputNumberModal.svelte'), { sel });
					break;

				// date
				case 'input_datetime':
				case 'datetime':
					openModal(() => import('$lib/Modal/InputDateModal.svelte'), { sel });
					break;

				// select
				case 'input_select':
				case 'select':
					openModal(() => import('$lib/Modal/InputSelectModal.svelte'), { sel });
					break;

				// text
				case 'input_text':
				case 'text':
					openModal(() => import('$lib/Modal/InputTextModal.svelte'), { sel });
					break;

				case 'timer':
					openModal(() => import('$lib/Modal/TimerModal.svelte'), { sel });
					break;

				case 'vacuum':
					openModal(() => import('$lib/Modal/VacuumModal.svelte'), { sel });
					break;

				case 'lawn_mower':
					openModal(() => import('$lib/Modal/LawnMowerModal.svelte'), { sel });
					break;

				case 'valve':
					openModal(() => import('$lib/Modal/ValveModal.svelte'), { sel });
					break;

				case 'image':
					openModal(() => import('$lib/Modal/ImageModal.svelte'), { sel });
					break;

				case 'todo':
					openModal(() => import('$lib/Modal/TodoModal.svelte'), { sel });
					break;

				case 'counter':
					openModal(() => import('$lib/Modal/CounterModal.svelte'), { sel });
					break;

				case 'alarm_control_panel':
					openModal(() => import('$lib/Modal/AlarmControlPanelModal.svelte'), { sel });
					break;

				case 'lock':
					openModal(() => import('$lib/Modal/LockModal.svelte'), { sel });
					break;

				case 'climate':
					openModal(() => import('$lib/Modal/ClimateModal.svelte'), { sel });
					break;

				case 'camera':
					openModal(() => import('$lib/Modal/CameraModal.svelte'), { sel });
					break;

				case 'water_heater':
					openModal(() => import('$lib/Modal/WaterHeaterModal.svelte'), { sel });
					break;

				case 'humidifier':
					openModal(() => import('$lib/Modal/HumidifierModal.svelte'), { sel });
					break;

				case 'media_player':
					openModal(() => import('$lib/Modal/MediaPlayer.svelte'), {
						selected: sel
					});
					break;

				case 'group':
					openModal(() => import('$lib/Modal/GroupModal.svelte'), { sel });
					break;

				case 'device_tracker': {
					if ($states?.[sel?.entity_id]?.attributes?.source_type === 'gps') {
						openModal(() => import('$lib/Modal/DeviceTrackerModal.svelte'), { sel });
					} else {
						openModal(() => import('$lib/Modal/SensorModal.svelte'), { sel });
					}
					break;
				}

				case 'cover':
					openModal(() => import('$lib/Modal/CoverModal.svelte'), {
						selected: sel
					});
					break;

				case 'fan':
					openModal(() => import('$lib/Modal/FanModal.svelte'), {
						selected: sel
					});
					break;

				default:
					openModal(() => import('$lib/Modal/Unknown.svelte'), {
						selected: sel
					});
					break;
			}
		}
	}

	/**
	 * Preloads module before click event
	 */
	async function handlePointerEvent() {
		if ($editMode) {
			await import('$lib/Modal/ButtonConfig.svelte');
		} else {
			switch (getDomain(sel?.entity_id)) {
				case 'light':
					await import('$lib/Modal/LightModal.svelte');
					break;
				case 'switch':
					await import('$lib/Modal/SwitchModal.svelte');
					break;
				case 'climate':
					await import('$lib/Modal/ClimateModal.svelte');
					break;
				case 'media_player':
					await import('$lib/Modal/MediaPlayer.svelte');
					break;
				default:
					await import('$lib/Modal/Unknown.svelte');
					break;
			}
		}
	}

	////// templates //////

	$: if ($config?.state === 'RUNNING' && sel?.template) {
		// for each changed entry in template
		Object.entries(sel?.template as Record<string, string>).forEach(([key, value]) => {
			const compareTemplate = value === template?.[key]?.input;
			const compareEntityId = sel?.entity_id === template?.[key]?.entity_id;
			if (compareTemplate && compareEntityId) return;
			renderTemplate(key, value);
		});
	}

	let unsubscribe: () => void;

	async function renderTemplate(key: string, value: string) {
		if (!$connection || !sel?.id) return;

		try {
			unsubscribe = await $connection.subscribeMessage(
				(response: { result: string } | { error: string; level: 'ERROR' | 'WARNING' }) => {
					let data: any = {
						input: value
					};

					if ('result' in response) {
						data.output =
							key === 'state' || key === 'name'
								? marked.parseInline(String(response.result))
								: String(response.result);
					} else if (response?.level === 'ERROR') {
						console.error(response.error);
						data.error = response.error;
					}

					data.entity_id = sel?.entity_id;

					$templates[sel?.id] = { ...$templates[sel?.id], [key]: data };
				},
				{
					type: 'render_template',
					template: value,
					report_errors: true,
					variables: {
						entity_id: sel?.entity_id
					}
				}
			);
		} catch (error) {
			console.error('Template error:', error);
		}
	}

	onDestroy(() => unsubscribe?.());
</script>

<div
	class="button-wrap"
	class:tile-fill={isTile}
	bind:this={container}
	data-state={stateOn}
	tabindex="-1"
	style={!$editMode ? 'cursor: pointer;' : ''}
	on:pointerenter={handlePointer}
	on:pointerdown={handlePointer}
>
	<DashboardCard
		variant={isTile ? 'tile' : 'row'}
		active={stateOn}
		glowColor={iconColor}
		editMode={$editMode}
		minHeight={cardMinHeight}
		sublabel={isTile ? undefined : sublabel}
		rippleOptions={!$editMode
			? {
					...$ripple,
					color: stateOn ? 'rgba(0, 0, 0, 0.22)' : 'rgba(255, 255, 255, 0.12)'
				}
			: { color: 'rgba(0, 0, 0, 0)', opacity: 0 }}
	>
		<div
			slot="icon"
			class="left"
			on:click|stopPropagation={(event) => {
				if (!$editMode) {
					toggle();
				} else {
					handleEvent(event);
				}
			}}
			on:keydown
			role="button"
			tabindex="0"
		>
			<div
				class="icon"
				class:icon-tile={isTile}
				class:icon-active={stateOn}
				class:icon-pulse={stateOn && !loading && !isTile}
				style:--icon-size={iconSizeVar || undefined}
				style:--icon-color={iconColor}
				style:background-color={sel?.template?.color && template?.color?.output
					? template?.color?.output
					: undefined}
				style:background-image={!icon && attributes?.entity_picture
					? `url(${attributes?.entity_picture})`
					: image && icon
						? `url(${icon})`
						: 'none'}
				class:image
			>
				{#if loading}
					<img src="loader.svg" alt="loading" style="margin:0 auto" />
				{:else if image || (!icon && attributes?.entity_picture)}
					&nbsp;
				{:else if icon}
					{#await loadIcon(icon)}
						<Icon icon="ooui:help-ltr" height="none" width="100%" />
					{:then resolvedIcon}
						<Icon icon={resolvedIcon} height="none" width="100%" />
					{:catch}
						<Icon icon="ooui:help-ltr" height="none" width="100%" />
					{/await}
				{:else if entity_id}
					<ComputeIcon {entity_id} />
				{:else}
					<Icon icon="ooui:help-ltr" height="none" width="100%" />
				{/if}
			</div>
		</div>

		<div
			class="right"
			class:right-tile={isTile}
			on:click|stopPropagation={handleEvent}
			on:keydown
			role="button"
			tabindex="0"
		>
			<div class="name" class:name-tile={isTile} class:name-on={stateOn}>
				{@html (sel?.template?.name && template?.name?.output) ||
					getName(sel, entity, sectionName) ||
					$lang('unknown')}
			</div>
			<div class="state" class:state-tile={isTile} class:state-on={stateOn}>
				{#if marquee}
					<div style="width: min-content;" bind:clientWidth={contentWidth}>
						{#if sel?.state || (sel?.template?.state && template?.state?.output)}
							{@html sel?.state || template?.state?.output}
						{:else if sel?.template?.set_state && template?.set_state?.output}
							{@html sel?.template?.set_state && $lang(template?.set_state?.output)}
						{:else}
							<StateLogic {entity_id} selected={sel} {contentWidth} />
						{/if}
					</div>
				{:else}
					<div class="state-clip">
						{#if sel?.state || (sel?.template?.state && template?.state?.output)}
							{@html sel?.state || template?.state?.output}
						{:else if sel?.template?.set_state && template?.set_state?.output}
							{@html sel?.template?.set_state && $lang(template?.set_state?.output)}
						{:else}
							<StateLogic {entity_id} selected={sel} {contentWidth} />
						{/if}
					</div>
				{/if}
			</div>
		</div>
	</DashboardCard>
</div>

<style>
	.button-wrap {
		font-family: 'Inter Variable', Inter, system-ui, sans-serif;
		width: 100%;
		height: 100%;
		min-height: inherit;
		margin: 0;
		transform: translateZ(0);
		display: flex;
		flex-direction: column;
	}

	.image {
		background-size: cover;
		background-repeat: no-repeat;
	}

	.left {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.right {
		display: flex;
		min-width: 0;
		flex-direction: column;
		justify-content: center;
		overflow: hidden;
		text-align: left;
	}

	.right-tile {
		text-align: center;
		align-items: center;
		justify-content: flex-end;
		flex: 1;
		min-height: 0;
		padding-bottom: 0.15rem;
	}

	.name-tile {
		font-size: 0.72rem;
		font-weight: 600;
		line-height: 1.2;
		white-space: normal;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}

	.state-tile {
		font-size: 0.68rem;
		margin-top: 0.1rem;
		white-space: normal;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}

	.icon {
		--icon-size: 2.35rem;
		height: var(--icon-size);
		width: var(--icon-size);
		max-width: 100%;
		max-height: 100%;
		color: rgba(255, 255, 255, 0.55);
		background-color: rgba(0, 0, 0, 0.22);
		border-radius: 50%;
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 0.45rem;
		background-position: center center;
		background-size: cover;
		background-repeat: no-repeat;
		transition:
			color 260ms cubic-bezier(0.22, 1, 0.36, 1),
			background-color 260ms cubic-bezier(0.22, 1, 0.36, 1),
			box-shadow 320ms ease,
			transform 200ms ease;
	}

	.icon-tile {
		border-radius: 0.9rem;
		padding: 0.4rem;
	}

	.icon-active {
		color: white;
		background-color: var(--icon-color);
		box-shadow:
			0 0 0 1px rgba(255, 255, 255, 0.15),
			0 4px 20px rgba(0, 0, 0, 0.35),
			0 0 28px -4px var(--icon-color);
	}

	@media (prefers-reduced-motion: no-preference) {
		.icon-pulse {
			animation: icon-bloom 2.8s ease-in-out infinite;
		}
	}

	@keyframes icon-bloom {
		0%,
		100% {
			filter: brightness(1);
		}
		50% {
			filter: brightness(1.08);
		}
	}

	.name {
		font-weight: 600;
		letter-spacing: -0.01em;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		font-size: 0.92rem;
		color: rgba(255, 255, 255, 0.88);
	}

	.name-on {
		color: rgba(255, 255, 255, 0.98);
	}

	.state {
		font-weight: 500;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		color: rgba(255, 255, 255, 0.48);
		font-size: 0.84rem;
	}

	.state-on {
		color: rgba(255, 255, 255, 0.72);
	}

	.state-clip {
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.tile-fill {
		min-height: 100%;
	}

	.tile-fill :global(.dashboard-card-press) {
		flex: 1;
		min-height: 0;
		display: flex;
		flex-direction: column;
	}

	.tile-fill :global(.dashboard-card-surface) {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-height: 0 !important;
	}

	@media all and (max-width: 768px) {
		.button-wrap:not(.tile-fill) {
			width: 100%;
			max-width: 100%;
		}
	}
</style>
