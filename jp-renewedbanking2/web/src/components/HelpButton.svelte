<!--
  HelpButton.svelte — 「？」ヘルプ（jp-renewedbanking2 追加）
  原作: Renewed-Banking — CC BY-NC-SA 4.0
-->
<script lang="ts">
  import { showHelp } from '../store/stores';

  /** ヘルプトピック（HelpModal の topicMeta と対応） */
  export let topic: 'deposit' | 'withdraw' | 'transfer' | 'create' | 'general' = 'general';

  function open() {
    showHelp.set(topic);
  }
</script>

<button type="button" class="help-btn" on:click={open} title="使い方" aria-label="使い方">
  ？
</button>

<style>
  .help-btn {
    flex-shrink: 0;
    width: 2.4rem;
    height: 2.4rem;
    border-radius: 50%;
    border: 1px solid rgba(255, 255, 255, 0.35);
    background: rgba(255, 255, 255, 0.08);
    color: #fff;
    font-size: 1.3rem;
    font-weight: 700;
    line-height: 1;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: background 0.15s, transform 0.15s;
  }
  .help-btn:hover {
    background: rgba(255, 165, 0, 0.35);
    transform: scale(1.06);
  }
</style>
