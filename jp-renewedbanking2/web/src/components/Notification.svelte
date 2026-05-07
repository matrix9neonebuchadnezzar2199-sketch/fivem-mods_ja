<script lang="ts">
    import { notify } from "../store/stores";
</script>

<section class="notification-container">
    <section class="notification-content">
        <i class="start-icon fa-solid fa-circle-info fa-2x" />
        <strong class="font__weight-bold notification-text">{$notify}</strong>
    </section>
</section>

<style>
    .notification-container {
        width: 15%;
        box-sizing: border-box;
        padding: 10px 8px;
        margin: 5px 0px;
        position: absolute;
        left: 5%;
        top: 4%;
    }
    .notification-content {
        background-color: var(--clr-primary);
        padding: 2rem;
        border-radius: 1rem;
        font-size: 1em;
    }
    .notification-text {
        font-size: 1rem;
    }
</style>
