<!--
  HelpModal.svelte — 使い方オーバーレイ（jp-renewedbanking2 追加）
  文言は locales/ja.json の _help_* を translations ストア経由で参照
-->
<script lang="ts">
  import { showHelp, translations } from '../store/stores';
  import { fade, scale } from 'svelte/transition';

  const topicMeta: Record<
    'general' | 'deposit' | 'withdraw' | 'transfer' | 'create',
    { titleKey: string; bodyKey: string }
  > = {
    general: { titleKey: '_help_title', bodyKey: '_help_intro' },
    deposit: { titleKey: '_help_deposit_title', bodyKey: '_help_deposit_body' },
    withdraw: { titleKey: '_help_withdraw_title', bodyKey: '_help_withdraw_body' },
    transfer: { titleKey: '_help_transfer_title', bodyKey: '_help_transfer_body' },
    create: { titleKey: '_help_create_title', bodyKey: '_help_create_body' },
  };

  function t(key: string): string {
    const tr = $translations;
    if (tr && typeof tr[key] === 'string') return tr[key] as string;
    return key;
  }

  $: topic = $showHelp;

  function close() {
    showHelp.set(null);
  }

  const subtopics = ['deposit', 'withdraw', 'transfer', 'create'] as const;
</script>

{#if topic}
  <!-- ESC でのクローズは VisibilityProvider の keyHandler が showHelp を null にする -->
  <div class="help-wrap" transition:fade={{ duration: 150 }}>
    <button
      type="button"
      class="backdrop"
      on:click={close}
      aria-label={t('_help_close')}
    ></button>
    <div
      class="modal"
      on:click|stopPropagation
      transition:scale={{ duration: 200, start: 0.92 }}
      role="dialog"
      aria-modal="true"
      aria-labelledby="help-modal-title"
    >
      <h2 id="help-modal-title">{t(topicMeta[topic].titleKey)}</h2>
      <pre class="body">{t(topicMeta[topic].bodyKey)}</pre>

      {#if topic === 'general'}
        <div class="topic-list">
          {#each subtopics as key}
            <button type="button" on:click={() => showHelp.set(key)}>
              {t(topicMeta[key].titleKey)}
            </button>
          {/each}
        </div>
      {/if}

      <button type="button" class="close" on:click={close}>{t('_help_close')}</button>
    </div>
  </div>
{/if}

<style>
  .help-wrap {
    position: fixed;
    inset: 0;
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
  }
  .backdrop {
    position: absolute;
    inset: 0;
    border: none;
    margin: 0;
    padding: 0;
    background: rgba(0, 0, 0, 0.55);
    cursor: pointer;
    pointer-events: auto;
    font: inherit;
  }
  .modal {
    position: relative;
    z-index: 1;
    pointer-events: auto;
    background: #1f2937;
    color: #fff;
    border-radius: 12px;
    padding: 2rem;
    max-width: 52rem;
    width: 90%;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
    border: 1px solid rgba(255, 165, 0, 0.35);
  }
  h2 {
    margin-top: 0;
    color: #ffa500;
    font-size: 1.8rem;
  }
  .body {
    white-space: pre-wrap;
    line-height: 1.65;
    font-family: inherit;
    font-size: 1.3rem;
    margin: 0;
  }
  .topic-list {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.8rem;
    margin: 1.6rem 0;
  }
  .topic-list button {
    background: #374151;
    color: #fff;
    border: none;
    padding: 1rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1.2rem;
  }
  .topic-list button:hover {
    background: #ffa500;
    color: #111;
  }
  .close {
    width: 100%;
    padding: 1rem;
    margin-top: 1.2rem;
    background: #ffa500;
    color: #111;
    border: none;
    border-radius: 6px;
    font-weight: 700;
    cursor: pointer;
    font-size: 1.3rem;
  }
</style>
