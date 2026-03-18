<script lang="ts">
	import { base } from '$app/paths';
	import { dashboard } from '$lib/Stores';

	export let initial: any;

	let themeRootCss = '';

	/**
	 * Map the theme entries into CSS variables
	 */
	$: {
		themeRootCss = Object.entries(initial?.theme || {})
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
</script>

<svelte:head>
	<!-- split tag so PostCSS does not treat this as a Svelte <style> block -->
	{@html '<' + 'style>:root {' + themeRootCss + '}</' + 'style>'}
	<meta name="theme-color" content={initial?.theme?.['app-color']} />
</svelte:head>
