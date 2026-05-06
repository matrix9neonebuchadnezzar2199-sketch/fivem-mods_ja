<script lang="ts">
    import { accounts, translations } from "../../store/stores";
    import AccountListItem from "./AccountListItem.svelte";
    import HelpButton from "../HelpButton.svelte";
    let accSearch = "";
    $: filteredAccounts = $accounts.filter((item: any) =>
        item.name.toLowerCase().includes(accSearch.toLowerCase())
    );
</script>

<aside>
    <div class="heading-row">
        <h3 class="heading">{$translations.accounts}</h3>
        <HelpButton topic="general" />
    </div>
    <input type="text" class="acc-search" placeholder={$translations.account_search} bind:value={accSearch} />
    <section class="scroller">
        {#if filteredAccounts.length > 0}
            {#each filteredAccounts as account (account.id)}
                <AccountListItem {account} />
            {/each}
        {:else}
            <h3 style="text-align: left; color: #F3F4F5; margin-top: 1rem;">{$translations.account_not_found}</h3>
        {/if}
    </section>
</aside>

<style>
    .heading-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.8rem;
        margin-bottom: 0.4rem;
    }
    aside {
        flex: 0 0 25%;
        padding-left: 1rem;
        padding-top: 0.4rem;
    }
    .acc-search {
        width: 100%;
        border-radius: 5px;
        border: none;
        padding: 1.4rem;
        margin-bottom: 1rem;
        background-color: var(--clr-primary-light);
        color: #fff;
    }
</style>
