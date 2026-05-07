<!--
  可視フラグに応じて子を描画。NUI メッセージで口座・ロケールを同期
-->
<script lang="ts">
  import { fetchNui } from '../utils/fetchNui';
  import { onMount } from 'svelte';
  import { 
    visibility,
    accounts,
    activeAccount,
    loading,
    notify,
    popupDetails,
    atm,
    allowDepositAtAtm,
    translations,
    currency,
    showHelp,
  } from '../store/stores';
  import { useNuiEvent } from '../utils/useNuiEvent';
  let isVisible: boolean;

  visibility.subscribe(visible => {
    isVisible = visible;
  });

  useNuiEvent<any>('setVisible', data => {
    accounts.set(data.accounts);
    activeAccount.update(() => data.accounts[0].id)
    visibility.set(data.status);
    loading.set(data.loading);
    atm.set(data.atm);
    allowDepositAtAtm.set(data.allowDepositAtAtm !== false);
  })

  useNuiEvent<any>('setLoading', data => {
    loading.set(data.status);
  })

  useNuiEvent<any>('notify', data => {
    notify.set(data.status);
    setTimeout(() => {
      notify.set("");
    }, 3500);
  })

  useNuiEvent<any>('updateLocale', data => {
    translations.set(data.translations);
    currency.set(data.currency);
  })

  useNuiEvent('setBankingHidden', () => {
    visibility.set(false);
    showHelp.set(null);
    popupDetails.update((val) => ({
      ...val,
      actionType: '',
    }));
    loading.set(false);
  });
  
  onMount(() => {
    const keyHandler = (e: KeyboardEvent) => {
      if (isVisible && ['Escape'].includes(e.code)) {
        fetchNui('closeInterface');
        visibility.set(false);
        showHelp.set(null);
        popupDetails.update((val) => ({
          ...val,
          actionType: "",
        }));
      }
    };

    window.addEventListener('keydown', keyHandler);
    return () => window.removeEventListener('keydown', keyHandler);
  });
</script>

{#if isVisible}
  <slot />
{/if}
