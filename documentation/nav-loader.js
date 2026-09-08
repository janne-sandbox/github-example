(function () {
    const sidebar = document.querySelector('[data-generated-nav]');
    if (!sidebar) return;

    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const sections = [
        ['Hello World clock', [
            ['index.html', 'Documentation home'],
            ['clock-overview.html', 'Architecture and behavior'],
            ['clock-development.html', 'Local development'],
            ['github-actions.html', 'GitHub Actions'],
            ['code-review.html', 'Offline code review'],
            ['event-catalog.html', 'Event catalog']
        ]]
    ];

    const navSections = sections.map(([title, links]) => {
        const navLinks = links.map(([href, label]) => {
            const active = href === currentPage ? ' active' : '';
            const current = href === currentPage ? ' aria-current="page"' : '';
            return `<a class="nav-item${active}" href="${href}"${current}>${label}</a>`;
        }).join('');
        return `<div class="nav-section">
            <div class="nav-section-title">${title}</div>
            ${navLinks}
        </div>`;
    }).join('');

    sidebar.innerHTML = `
        <div class="logo-container">
            <img src="nologo-white.svg" alt="NoLogo">
            <h1>Example project documentation</h1>
        </div>
        <nav class="nav-menu" aria-label="Project documentation">
            ${navSections}
        </nav>`;
}());
