<!--
  Renewed-Banking NUI ルート（jp-renewedbanking2: HelpModal を追加）
-->
<script lang="ts">
    import VisibilityProvider from "./providers/VisibilityProvider.svelte";
    import { debugData } from "./utils/debugData";
    import AccountsContainer from "./components/AccountsContainer.svelte";
    import Popup from "./components/Popup.svelte";
    import Loading from "./components/Loading.svelte";
    import Notification from "./components/Notification.svelte";
    import HelpModal from "./components/HelpModal.svelte";
    import { popupDetails, loading, notify } from "./store/stores";
    import { devBrowserTranslations } from "./utils/devBrowserTranslations";

    debugData([
        {
            action: "updateLocale",
            translations: devBrowserTranslations,
            currency: "USD",
        },
        {
            action: "setVisible",
            status: true,
            accounts: [
                {
                    id: "BROWSER-001",
                    type: "Personal",
                    name: "Browser Preview",
                    frozen: false,
                    amount: 25000,
                    cash: 1200,
                    transactions: [],
                },
            ],
            loading: false,
            atm: false,
        },
    ]);
</script>

<svelte:head>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.2/css/all.min.css" integrity="sha512-1sCRPdkRXhBV2PBLUdRb4tMg1w2YPf37qatUFeS7zlBy7jJI8Lf4VHwWfZZfpXtYSLy85pkm9GaYVYMfw5BC1A==" crossorigin="anonymous" referrerpolicy="no-referrer" />
</svelte:head>
<VisibilityProvider>
    <AccountsContainer />
    <HelpModal />
    {#if $popupDetails.actionType !== ""}
        <Popup />
    {/if}
    {#if $notify !== ""}
        <Notification />
    {/if}
</VisibilityProvider>
{#if $loading}
    <Loading />
{/if}
