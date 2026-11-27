import { withMermaid } from 'vitepress-plugin-mermaid'

// one sidebar in reading order: the "previous" and "next" links at the bottom of each page
// follow it, so the documentation reads from the first page to the last
const docs = [
  {
    text: 'Start here',
    items: [
      { text: 'Introduction',   link: '/guide/' },
      { text: 'Fresh install',  link: '/guide/installation' },
      { text: 'Updating',       link: '/guide/updating' },
      { text: 'The machines',   link: '/guide/machines' },
    ],
  },
  {
    text: 'How it works',
    items: [
      { text: 'Stow and dotify.sh', link: '/guide/dotify' },
      { text: 'Repository layout',  link: '/guide/layout' },
      { text: 'Conventions',        link: '/guide/conventions' },
    ],
  },
  {
    text: 'Packages',
    items: [
      { text: 'bash',                 link: '/packages/bash' },
      { text: 'vim',                  link: '/packages/vim' },
      { text: 'Neovim',               link: '/packages/nvim' },
      { text: 'git',                  link: '/packages/git' },
      { text: 'tmux',                 link: '/packages/tmux' },
      { text: 'ssh',                  link: '/packages/ssh' },
      { text: 'Python and LaTeX',     link: '/packages/python-latex' },
      { text: 'HPC modules (Lmod)',   link: '/packages/modules' },
      { text: 'scripts',              link: '/packages/scripts' },
      { text: 'quark desktop',        link: '/packages/desktop-quark' },
      { text: 'astrobit desktop',     link: '/packages/desktop-astrobit' },
      { text: 'Per-host packages',    link: '/packages/host-specific' },
    ],
  },
  {
    text: 'Claude Code',
    items: [
      { text: 'Overview and all pages', link: '/claude/' },
    ],
  },
  {
    text: 'Recipes',
    items: [
      { text: 'Cookbook',        link: '/guide/cookbook' },
      { text: 'Troubleshooting', link: '/guide/troubleshooting' },
    ],
  },
]

// the Claude Code section has its own sidebar: five groups in reading order, every page one click away.
// The top-nav "Claude Code" menu is built from the same list, so any page reaches any Claude page.
const claudeGroups = [
  {
    text: 'Setup',
    items: [
      { text: 'The claude package',  link: '/claude/package' },
      { text: 'Global instructions', link: '/claude/instructions' },
    ],
  },
  {
    text: 'Starting sessions',
    items: [
      { text: 'Session commands',      link: '/claude/sessions' },
      { text: 'Subscription accounts', link: '/claude/accounts' },
      { text: 'Local models',          link: '/claude/local-llm' },
      { text: 'Model utilities',       link: '/claude/model-tools' },
      { text: 'Environment reference', link: '/claude/environment' },
    ],
  },
  {
    text: 'Extending Claude Code',
    items: [
      { text: 'Skills',           link: '/claude/skills' },
      { text: 'Skills inventory', link: '/claude/skills-inventory' },
      { text: 'Slash commands',   link: '/claude/commands' },
      { text: 'Hooks',            link: '/claude/hooks' },
      { text: 'Agents',           link: '/claude/agents' },
      { text: 'Status line',      link: '/claude/statusline' },
    ],
  },
  {
    text: 'Workflows',
    items: [
      { text: 'Night protocol', link: '/claude/night-protocol' },
      { text: 'Plan issues',    link: '/claude/plan-issue' },
      { text: 'Bug issues',     link: '/claude/bug-issue' },
    ],
  },
  {
    text: 'Delegating to executors',
    items: [
      { text: 'Delegating to an executor', link: '/claude/delegate' },
      { text: 'Executors',                 link: '/claude/executors' },
      { text: 'Executor benchmarks',       link: '/claude/executor-benchmarks' },
    ],
  },
]

const claude = [
  { text: 'Claude Code', items: [{ text: 'Overview', link: '/claude/' }] },
  ...claudeGroups.map((g) => ({ ...g, collapsed: false })),
  { text: 'Back to the dotfiles', items: [{ text: 'Cookbook', link: '/guide/cookbook' }] },
]

export default withMermaid({
  title: 'dotfiles',
  description: "Stefano Zaghi's dotfiles: an HPC workstation, a laptop and a telescope controller from one git repository",
  base: '/dotfiles/',
  cleanUrls: true,
  lastUpdated: true,
  appearance: 'dark',
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/dotfiles/favicon.svg' }],
    ['meta', { name: 'theme-color', content: '#002b36' }],
  ],
  themeConfig: {
    logo: { light: '/logo.svg', dark: '/logo-dark.svg' },
    siteTitle: 'dotfiles',
    socialLinks: [{ icon: 'github', link: 'https://github.com/szaghi/dotfiles' }],
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Start here', link: '/guide/', activeMatch: '^/guide/(index|installation|updating|machines)?$' },
      { text: 'How it works', link: '/guide/dotify', activeMatch: '^/guide/(dotify|layout|conventions)' },
      { text: 'Packages', link: '/packages/bash', activeMatch: '^/packages/' },
      {
        text: 'Claude Code',
        activeMatch: '^/claude/',
        items: [{ text: 'Overview', link: '/claude/' }, ...claudeGroups],
      },
      { text: 'Cookbook', link: '/guide/cookbook', activeMatch: '^/guide/(cookbook|troubleshooting)' },
    ],
    sidebar: { '/guide/': docs, '/packages/': docs, '/claude/': claude },
    outline: { level: [2, 3] },
    search: { provider: 'local' },
    editLink: {
      pattern: 'https://github.com/szaghi/dotfiles/edit/master/docs/:path',
      text: 'Edit this page on GitHub',
    },
    footer: { message: 'Deployed with GNU Stow', copyright: 'WTFPL · Stefano Zaghi' },
  },
  mermaid: {},
  vite: {
    // mermaid 11.16+ ships destructuring that esbuild refuses to lower to Vite's default es2020
    // target, and the build dies: es2022 needs no lowering (same fix as FoXy's docs)
    build: { target: 'es2022' },
    optimizeDeps: { include: ['mermaid'] },
  },
})
