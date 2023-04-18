<script>
  import Counter from './lib/Counter.svelte'
</script>

<main>
  <h1>Bananapus Rewards</h1>

  <div class="card">
    <Counter />
  </div>

  <p>
    Join the <a href="https://discord.gg/ErQYmth4dS">Discord server</a> to learn more.
  </p>

</main>

<style>
  .logo {
    height: 6em;
    padding: 1.5em;
    will-change: filter;
    transition: filter 300ms;
  }
  .logo:hover {
    filter: drop-shadow(0 0 2em #646cffaa);
  }
  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00aa);
  }
</style>
