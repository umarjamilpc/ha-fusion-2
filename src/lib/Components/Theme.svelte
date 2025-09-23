<script lang="ts">
	import { base } from '$app/paths';
	import { dashboard } from '$lib/Stores';

	export let initial: any;
	export let theme: any;

	let css: string;

	$: if (theme) update(theme);

	/**
	 * Map the theme entries into CSS variables
	 */
	$: {
		css = Object.entries(initial?.theme || {})
			.map(([key, value]) => {
				if (typeof value === 'string' && value.includes('/themes/')) {
					value = value.replace('/', `${base}/`);
				}
				return `--theme-${key}: ${value};`;
			})
			.join(' ');

		if ($dashboard?.theme && !import.meta.env.SSR) {
			if (initial?.title !== $dashboard.theme) {
				loadTheme($dashboard.theme);
			}
		}
	}

	/**
	 * Load theme by name from backend
	 */
	async function loadTheme(name: string) {
		try {
			const response = await fetch(`${base}/_api/load_theme`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ theme: name })
			});

			const data = await response.json();

			if (response.ok) {
				initial = data;
			} else {
				throw new Error(data.message);
			}
		} catch (error) {
			console.error(error);
		}
	}

	function update(theme: any) {
		css = `
			/* button */
			--theme-button-background-color-off: ${theme?.['button-background-color-off'] || '#414141'};
			--theme-button-name-color-off: ${theme?.['button-name-color-off'] || 'white'};
			--theme-button-state-color-off: ${theme?.['button-state-color-off'] || '#a7a7a7'};
			--theme-button-background-color-on: ${theme?.['button-background-color-on'] || '#f2f2f2'};
			--theme-button-name-color-on: ${theme?.['button-name-color-on'] || 'black'};
			--theme-button-state-color-on: ${theme?.['button-state-color-on'] || '#5c5c5c'};

			/* history */
			--theme-history-color: ${theme?.['history-color'] || '#323232'};
		`;
	}
</script>

<svelte:head>
	{@html `<style>${css}</style>`}
</svelte:head>