<script lang="ts">
    import AccountsList from "./Accounts/AccountsList.svelte";
    import AccountTransactionsList from "./Accounts/AccountTransactionsList.svelte";
    import { accounts, visibility, showHelp, popupDetails } from '../store/stores';
    import { formatMoney } from "../utils/misc";
    import { fetchNui } from "../utils/fetchNui";

    function closeMainUi() {
        fetchNui('closeInterface');
        visibility.set(false);
        showHelp.set(null);
        popupDetails.update((val) => ({ ...val, actionType: '' }));
    }
</script>

<div class="main">
    <button type="button" class="main-close" on:click={closeMainUi} aria-label="閉じる">×</button>
    <section>
        <AccountsList />
        <AccountTransactionsList />
    </section>
    {#if $accounts && $accounts.length > 0}
        <h5>
            <i class="fa-solid fa-wallet fa-fw"></i>{formatMoney($accounts[0]?.cash)}
        </h5>
    {/if}
</div>

<style>
    .main {
        overflow: hidden;
        width: 90%;
        height: 90%;
        bottom: 5%;
        left: 5%;
        padding: 1rem;
        position: absolute;
        background-color: rgb(32, 41, 48);
        border-radius: 5px;
        border: 4px solid #393A45;
        background-size: cover;
        background-position: center;
        opacity: 1;
    }

    section {
        display: flex;
        gap: 4rem;
        height: calc(100% - 2rem);
    }
    h5 {
        font-size: 1.4rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .main-close {
        position: absolute;
        top: 12px;
        right: 12px;
        z-index: 2;
        width: 40px;
        height: 40px;
        padding: 0;
        border: none;
        border-radius: 6px;
        font-size: 1.75rem;
        line-height: 1;
        cursor: pointer;
        color: #f3f4f5;
        background-color: #393a45;
    }

    .main-close:hover {
        background-color: #4a4b56;
    }

    .main-close:focus-visible {
        outline: 2px solid #f59e0b;
        outline-offset: 2px;
    }
</style>
