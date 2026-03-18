<script lang="ts">
	import {
		dashboard,
		configuration,
		editMode,
		motion,
		showDrawer,
		translation,
		drawerSearch,
		focusSearch,
		currentViewId,
		selectedLanguage,
		customJs,
		filterDashboard,
		disableMenuButton,
		clickOriginatedFromMenu,
		connection,
		youtubeAddon,
		layoutBreakpoint
	} from '$lib/Stores';
	import { authentication } from '$lib/Socket';
	import { onDestroy, onMount } from 'svelte';
	import { browser } from '$app/environment';
	import { modals } from 'svelte-modals';
	import Theme from '$lib/Components/Theme.svelte';

	/**
	 * Data from server-side load
	 * function +page.server.ts
	 */
	export let data;

	let altKeyPressed = false;

	$configuration = data?.configuration;
	$dashboard = data?.dashboard;
	$translation = data?.translations;
	$selectedLanguage = data?.configuration?.locale || 'en';
	$customJs = data?.configuration?.custom_js;
	$youtubeAddon = data?.configuration?.addons?.youtube;
	$currentViewId = $dashboard?.views?.[0]?.id;

	const _motion = data?.configuration?.motion;
	$motion = _motion === undefined || _motion === true ? $motion : 0;

	/**
	 * Computes the current view.
	 *
	 * filterDashboard is filtered from search input, else
	 * find `$currentViewId` OR when dragging get `isDndShadowItem`
	 */
	$: view = $drawerSearch
		? $filterDashboard
		: $dashboard?.views?.find((view) => view?.id === $currentViewId) ||
			$dashboard?.views?.find((view) => view?.isDndShadowItem);

	/**
	 * WebSocket, tries to reconnect if no previous connection has been made.
	 */
	let isConnecting = false;
	let retryInterval: ReturnType<typeof setInterval>;

	if (browser) {
		document.documentElement.lang = $selectedLanguage || 'en';

		connect();
		retryInterval = setInterval(connect, 3000);
	}

	async function connect() {
		if (isConnecting) return;
		isConnecting = true;

		console.debug('authenticating...');

		try {
			await authentication($configuration);
			console.debug('authenticated.');
			clearInterval(retryInterval);
		} catch {
			// catch but don't log
		} finally {
			isConnecting = false;
		}
	}

	/**
	 * Reconnect if long-lived access token changes
	 */
	$: if ($configuration?.token) updateConnection();

	function updateConnection() {
		if (isConnecting || !browser) return;
		clearInterval(retryInterval);

		connect();
		retryInterval = setInterval(connect, 3000);
	}

	onDestroy(() => {
		clearInterval(retryInterval);
		if (browser) window.removeEventListener('resize', syncLayoutBreakpoint);
	});

	function syncLayoutBreakpoint() {
		const w = window.innerWidth;
		if (w < 640) layoutBreakpoint.set('narrow');
		else if (w < 1024) layoutBreakpoint.set('mid');
		else layoutBreakpoint.set('wide');
	}

	onMount(async () => {
		syncLayoutBreakpoint();
		window.addEventListener('resize', syncLayoutBreakpoint);

		/**
		 * If the "menu" parameter in the URL is set to 'false'
		 * Menu button is hidden and drawer is disabled.
		 */
		const menuParam = new URLSearchParams(window.location.search).get('menu');
		$disableMenuButton = menuParam === 'false';

		/**
		 * Unregister service worker because it
		 * interferes with MJPEG camera streams
		 */
		if ('serviceWorker' in navigator) {
			try {
				const registrations = await navigator.serviceWorker.getRegistrations();
				for (const registration of registrations) {
					await registration.unregister();
				}
			} catch (error) {
				console.error('Error during service worker unregistration:', error);
			}
		}
	});

	/**
	 * Toggles drawer visibility and resets
	 * the `$clickOriginatedFromMenu` flag.
	 */
	function toggleDrawer() {
		$showDrawer = !$showDrawer;
		$clickOriginatedFromMenu = false;
	}

	/**
	 * If in edit mode, toggle editMode by programmatically clicking `EditModeButton`
	 * to trigger any potential confirm dialogs. Else toggle drawer normally.
	 */
	function handleClick() {
		if ($editMode) {
			$clickOriginatedFromMenu = true;
			const button = document.querySelector('#editmode') as HTMLButtonElement;
			button?.click();
		} else {
			toggleDrawer();
		}
	}

	/**
	 * Handles the keydown events for:
	 * - 'Escape': Hides the search focus/hides the drawer.
	 * - 'Alt': Copy item on drag-and-drop
	 * - 'f': Shows drawer and/or focuses on the search field.
	 */
	function handleKeydown(event: KeyboardEvent) {
		if ($modals.length) return;

		// don't focus on underlying element
		if (event.key === 'Escape' && !$editMode && document.activeElement) {
			(document.activeElement as HTMLElement).blur();
		}

		if (event.key === 'Alt') {
			altKeyPressed = true;
		}

		if (event.key === 'f' && !$disableMenuButton) {
			if (!$showDrawer || !$focusSearch) {
				$focusSearch = true;
				if (!$showDrawer) $showDrawer = true;
				event.preventDefault(); // prevent 'f'
			}
		} else if (event.key === 'Escape' && $showDrawer && !$editMode) {
			$focusSearch = false;
			if (!$drawerSearch) handleClick();
			$drawerSearch = undefined;
		}
	}

	/**
	 * Handle Alt key press and release events for copy-on-drag
	 */
	function handleKeyup(event: KeyboardEvent) {
		if (event.key === 'Alt') {
			altKeyPressed = false;
		}
	}

	$: hasSidebar = Boolean($dashboard?.sidebar?.length && !$dashboard?.hide_sidebar);
	$: hasFooterDock = Boolean(($dashboard?.footer?.items || []).length);
	$: hassTabletPreset = $dashboard?.ui?.design_preset === 'hass_tablet';
	$: sidebarPx =
		!hasSidebar || $layoutBreakpoint === 'narrow'
			? 0
			: $layoutBreakpoint === 'mid'
				? Math.min($dashboard?.sidebarWidth || 350, 260)
				: $dashboard?.sidebarWidth || 350;
</script>

<svelte:window on:keydown={handleKeydown} on:keyup={handleKeyup} />

<!-- theme -->
<Theme initial={data?.theme} />

<div
	id="layout"
	class:layout-narrow={$layoutBreakpoint === 'narrow'}
	class:layout-mid={$layoutBreakpoint === 'mid'}
	class:design-hass-tablet={hassTabletPreset}
	class:has-footer-dock={hasFooterDock}
	style:grid-template-columns="{sidebarPx}px minmax(0, 1fr)"
	style:grid-template-rows={$showDrawer
		? hasFooterDock
			? 'auto auto 1fr auto'
			: 'auto auto 1fr'
		: hasFooterDock
			? '0fr auto 1fr auto'
			: '0fr auto 1fr'}
	style:transition="grid-template-rows {$motion}ms ease, grid-template-columns {$motion}ms ease"
>
	<!-- nav -->
	{#await import('$lib/Main/Views.svelte') then Views}
		<svelte:component this={Views.default} {view} />
	{/await}

	<!-- main -->
	{#if view?.sections}
		{#await import('$lib/Main/Index.svelte') then Main}
			<svelte:component this={Main.default} {view} {altKeyPressed} />
		{/await}
	{:else if $connection}
		{#await import('$lib/Main/Intro.svelte') then Intro}
			<svelte:component this={Intro.default} {data} />
		{/await}
	{/if}

	<!-- aside -->
	{#await import('$lib/Sidebar/Index.svelte') then Sidebar}
		<svelte:component this={Sidebar.default} {altKeyPressed} />
	{/await}

	<!-- menu -->
	{#if !$disableMenuButton}
		{#await import('$lib/Drawer/MenuButton.svelte') then MenuButton}
			<svelte:component this={MenuButton.default} {handleClick} />
		{/await}
	{/if}

	<!-- header -->
	{#if $showDrawer}
		{#await import('$lib/Drawer/Index.svelte') then Drawer}
			<svelte:component this={Drawer.default} {view} {data} {toggleDrawer} />
		{/await}
	{/if}

	<!-- module -->
	{#if $customJs}
		{#await import('$lib/Components/CustomJs.svelte') then CustomJs}
			<svelte:component this={CustomJs.default} />
		{/await}
	{/if}

	{#await import('$lib/Main/FooterDock.svelte') then FooterDock}
		<svelte:component this={FooterDock.default} />
	{/await}
</div>

<style>
	@import '$lib/styles/hass-tablet-preset.css';

	/* Desktop & tablet: sidebar + main (hass-config style) */
	#layout {
		display: grid;
		grid-template-areas:
			'header header'
			'aside nav'
			'aside main';
		min-height: 100vh;
		overflow: hidden;
	}

	#layout.has-footer-dock {
		grid-template-areas:
			'header header'
			'aside nav'
			'aside main'
			'dock dock';
	}

	/* Tablet: slightly tighter chrome */
	#layout.layout-mid :global(aside) {
		border-right-width: 1px;
	}

	/* Phone: single column, sidebar hidden; room for floating menu */
	#layout.layout-narrow {
		grid-template-areas:
			'header header'
			'nav nav'
			'main main';
		grid-template-columns: minmax(0, 1fr) !important;
		grid-template-rows: auto auto 1fr !important;
		padding-bottom: env(safe-area-inset-bottom, 0);
	}

	#layout.layout-narrow.has-footer-dock {
		grid-template-areas:
			'header header'
			'nav nav'
			'main main'
			'dock dock';
		grid-template-rows: auto auto 1fr auto !important;
	}

	#layout.layout-narrow :global(aside) {
		display: none;
	}

	@media (min-width: 640px) and (max-width: 1023px) {
		#layout:not(.layout-narrow) {
			grid-template-rows: auto auto 1fr;
		}
	}
</style>
