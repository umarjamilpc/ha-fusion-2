<script lang="ts">
  import { sel, dashboard, record, lang } from '$lib/Stores';

  let size = $sel?.size || 50;

  $: $sel.size = size;
  $: $dashboard = $dashboard;

  function handleSizeChange() {
    $record();
  }
</script>

<div class="config-container">
  <h1>{$lang('square_config')}</h1>
  <div class="form-group">
    <label for="size">{$lang('size')}</label>
    <input type="number" id="size" bind:value={size} on:change={handleSizeChange}>
  </div>
</div>

<style>
  .config-container {
    padding: 1rem;
  }

  .form-group {
    margin-bottom: 1rem;
  }

  label {
    display: block;
    margin-bottom: 0.5rem;
  }

  input[type="number"] {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    box-sizing: border-box;
  }
</style>