<script lang="ts">
  import { configuration, lang } from '$lib/Stores';

  let entityShape: 'rectangle' | 'square' = $configuration.entityShape || 'rectangle';

  function handleShapeChange(event: Event) {
    entityShape = (event.target as HTMLSelectElement).value as 'rectangle' | 'square';
    $configuration.entityShape = entityShape;
  }
</script>

<div>
  <label for="entity-shape">{$lang('entity_shape')}</label>
  <select id="entity-shape" bind:value={entityShape} on:change={handleShapeChange}>
    <option value="rectangle">{$lang('rectangle')}</option>
    <option value="square">{$lang('square')}</option>
  </select>
</div>

<style>
  div {
    margin-bottom: 1rem;
  }

  label {
    display: block;
    margin-bottom: 0.5rem;
  }

  select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid var(--theme-colors-border);
    border-radius: 0.25rem;
    background-color: var(--theme-colors-background);
    color: var(--theme-colors-text);
  }
</style>