<script lang="ts">
	import { editMode, record, dashboard } from '$lib/Stores';
	import Icon from '@iconify/svelte';

	export let item: { width?: string; height?: string; type?: string };

	let resizing = false;
	let startX = 0;
	let startY = 0;
	let origW = 0;
	let origH = 0;
	let itemEl: HTMLElement | null = null;

	function onDown(e: PointerEvent) {
		if (!$editMode || item?.type !== 'button') return;
		e.stopPropagation();
		e.preventDefault();
		const parent = (e.currentTarget as HTMLElement).closest('.item') as HTMLElement;
		if (!parent) return;
		itemEl = parent;
		const r = parent.getBoundingClientRect();
		origW = r.width;
		origH = r.height;
		startX = e.clientX;
		startY = e.clientY;
		resizing = true;
	}

	function onMove(e: PointerEvent) {
		if (!resizing || !itemEl) return;
		const dw = e.clientX - startX;
		const dh = e.clientY - startY;
		const w = Math.max(72, Math.round(origW + dw));
		const h = Math.max(52, Math.round(origH + dh));
		item.width = `${w}px`;
		item.height = `${h}px`;
		$dashboard = $dashboard;
	}

	function onUpGlobal() {
		if (!resizing) return;
		resizing = false;
		itemEl = null;
		$record();
	}
</script>

<svelte:window on:pointermove={onMove} on:pointerup={onUpGlobal} on:pointercancel={onUpGlobal} />

{#if $editMode && item?.type === 'button'}
	<button
		type="button"
		class="resize-handle"
		aria-label="Drag to resize button"
		title="Resize"
		on:pointerdown={onDown}
	>
		<Icon icon="mdi:resize-bottom-right" width="1rem" height="1rem" />
	</button>
{/if}

<style>
	.resize-handle {
		position: absolute;
		right: 2px;
		bottom: 2px;
		z-index: 5;
		width: 1.75rem;
		height: 1.75rem;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 0;
		border: none;
		border-radius: 0.35rem;
		cursor: nwse-resize;
		touch-action: none;
		background: rgba(255, 193, 8, 0.85);
		color: #3b0f10;
		box-shadow: 0 1px 4px rgba(0, 0, 0, 0.35);
	}

	.resize-handle:hover {
		background: #ffc107;
	}
</style>
