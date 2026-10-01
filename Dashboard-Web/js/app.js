// ==========================================================
// PRODMON - APPLICATION WEB
// Gestion du menu, navigation, API et graphiques
// ==========================================================

document.addEventListener("DOMContentLoaded", function () {

    const menuButton = document.getElementById("menuButton");
    const sidebar = document.getElementById("sidebar");
    const mainContent = document.getElementById("mainContent");

    const navItems = document.querySelectorAll(".nav-item");
    const pages = document.querySelectorAll(".page");


    // ======================================================
    // GRAPHIQUES CHART.JS
    // ======================================================

    let productionChart = null;
    let temperatureChart = null;
    let machineStateChart = null;
    let alertTypeChart = null;


    // ======================================================
    // MENU HAMBURGER
    // ======================================================

    if (menuButton) {

        menuButton.addEventListener("click", function () {

            if (window.innerWidth > 800) {

                sidebar.classList.toggle("closed");
                mainContent.classList.toggle("expanded");

            } else {

                sidebar.classList.toggle("open");

            }

        });

    }


    // ======================================================
    // NAVIGATION ENTRE LES PAGES
    // ======================================================

    navItems.forEach(function (item) {

        item.addEventListener("click", function () {

            const pageId =
                item.getAttribute("data-page");


            navItems.forEach(function (nav) {

                nav.classList.remove("active");

            });


            item.classList.add("active");


            pages.forEach(function (page) {

                page.classList.remove("active-page");

            });


            const selectedPage =
                document.getElementById(pageId);


            if (selectedPage) {

                selectedPage.classList.add("active-page");

            }


            if (window.innerWidth <= 800) {

                sidebar.classList.remove("open");

            }


            // Charger les analyses lorsque
            // l'utilisateur ouvre la page Analyses

            if (pageId === "analytics") {

                loadAnalytics();

            }


            // Charger les interventions lorsque
            // l'utilisateur ouvre la page Interventions

            if (pageId === "interventions") {

                loadInterventions();

            }

        });

    });


    // ======================================================
    // BOUTON ACTUALISER DASHBOARD
    // ======================================================

    const refreshButton =
        document.getElementById("refreshDashboard");


    if (refreshButton) {

        refreshButton.addEventListener("click", function () {

            console.log(
                "Actualisation du dashboard ProdMon"
            );


            loadMachines();

            loadProduction();

            loadAlerts();

            loadNotifications();

            loadInterventions();

            loadUsers();

            loadAnalytics();

        });

    }


    // ======================================================
    // CHARGER LES MACHINES
    // ======================================================

    async function loadMachines() {

        const container =
            document.getElementById(
                "machinesContainer"
            );


        const machineCount =
            document.getElementById(
                "machineCount"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des machines...

            </p>

        `;


        try {

            const response =
                await fetch("/api/Machines");


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const machines =
                await response.json();


            // =================================================
            // KPI NOMBRE DE MACHINES
            // =================================================

            if (machineCount) {

                machineCount.textContent =
                    machines.length;

            }


            // =================================================
            // AUCUNE MACHINE
            // =================================================

            if (
                !Array.isArray(machines) ||
                machines.length === 0
            ) {

                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucune machine enregistrée.

                        </p>

                    </div>

                `;

                return;

            }


            // =================================================
            // AFFICHAGE DES MACHINES
            // =================================================

            container.innerHTML =
                machines.map(machine => {


                    const statut =
                        (
                            machine.statut ||
                            "INCONNU"
                        ).toUpperCase();


                    let statusClass =
                        "status-unknown";


                    let statusLabel =
                        statut;


                    if (statut === "RUNNING") {

                        statusClass =
                            "status-running";

                    }

                    else if (
                        statut === "STOPPED"
                    ) {

                        statusClass =
                            "status-stopped";

                    }

                    else if (
                        statut === "MAINTENANCE"
                    ) {

                        statusClass =
                            "status-maintenance";

                    }


                    const localisation =
                        machine.localisation ||
                        "Non définie";


                    const createdAt =
                        machine.createdAt

                            ? new Date(
                                machine.createdAt
                              ).toLocaleString(
                                  "fr-FR"
                              )

                            : "--";


                    return `

                        <div class="machine-card">


                            <div class="machine-card-header">


                                <div class="machine-icon">

                                    🏭

                                </div>


                                <span
                                    class="
                                        machine-status
                                        ${statusClass}
                                    "
                                >

                                    ${statusLabel}

                                </span>


                            </div>


                            <h3>

                                ${
                                    machine.nom ||
                                    `Machine ${machine.id}`
                                }

                            </h3>


                            <p class="machine-id">

                                Machine #${machine.id}

                            </p>


                            <div class="machine-info">


                                <div>

                                    <span>

                                        📍 Localisation

                                    </span>

                                    <strong>

                                        ${localisation}

                                    </strong>

                                </div>


                                <div>

                                    <span>

                                        📅 Créée le

                                    </span>

                                    <strong>

                                        ${createdAt}

                                    </strong>

                                </div>


                            </div>


                        </div>

                    `;

                }).join("");

        }

        catch (error) {

            console.error(
                "Erreur chargement machines :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les machines.

                    </p>

                </div>

            `;


            if (machineCount) {

                machineCount.textContent = "!";

            }

        }

    }


    // ======================================================
    // CRÉER / ACTUALISER LES GRAPHIQUES
    // ======================================================

    function createCharts(data) {


        if (
            !Array.isArray(data) ||
            data.length === 0
        ) {

            return;

        }


        // --------------------------------------------------
        // Trier les mesures chronologiquement
        // --------------------------------------------------

        const sortedData =
            [...data].sort((a, b) => {


                const dateA =
                    new Date(
                        a.mqttTimestamp ||
                        a.createdAt
                    );


                const dateB =
                    new Date(
                        b.mqttTimestamp ||
                        b.createdAt
                    );


                return dateA - dateB;

            });


        // --------------------------------------------------
        // Garder les 30 dernières mesures
        // --------------------------------------------------

        const chartData =
            sortedData.slice(-30);


        // --------------------------------------------------
        // Axe X : dates
        // --------------------------------------------------

        const labels =
            chartData.map(item => {


                const date =
                    item.mqttTimestamp ||
                    item.createdAt;


                if (!date) {

                    return "--";

                }


                return new Date(date)
                    .toLocaleString(
                        "fr-FR",
                        {
                            day: "2-digit",
                            month: "2-digit",
                            hour: "2-digit",
                            minute: "2-digit"
                        }
                    );

            });


        // --------------------------------------------------
        // Valeurs Production
        // --------------------------------------------------

        const productionValues =
            chartData.map(item => {

                return Number(
                    item.production ?? 0
                );

            });


        // --------------------------------------------------
        // Valeurs Température
        // --------------------------------------------------

        const temperatureValues =
            chartData.map(item => {


                if (
                    item.temperature === null ||
                    item.temperature === undefined
                ) {

                    return null;

                }


                return Number(
                    item.temperature
                );

            });


        // --------------------------------------------------
        // Canvas HTML
        // --------------------------------------------------

        const productionCanvas =
            document.getElementById(
                "productionChart"
            );


        const temperatureCanvas =
            document.getElementById(
                "temperatureChart"
            );


        // ==================================================
        // GRAPHIQUE PRODUCTION
        // ==================================================

        if (
            productionCanvas &&
            typeof Chart !== "undefined"
        ) {


            if (productionChart) {

                productionChart.destroy();

            }


            productionChart =
                new Chart(
                    productionCanvas,
                    {

                        type: "line",


                        data: {

                            labels: labels,


                            datasets: [

                                {

                                    label:
                                        "Production",

                                    data:
                                        productionValues,

                                    borderWidth: 3,

                                    tension: 0.3,

                                    fill: false,

                                    pointRadius: 4,

                                    pointHoverRadius: 7

                                }

                            ]

                        },


                        options: {

                            responsive: true,

                            maintainAspectRatio:
                                false,


                            interaction: {

                                mode: "index",

                                intersect: false

                            },


                            plugins: {

                                legend: {

                                    display: true,

                                    position: "top"

                                },


                                tooltip: {

                                    enabled: true

                                }

                            },


                            scales: {

                                x: {

                                    title: {

                                        display: true,

                                        text:
                                            "Date / heure"

                                    }

                                },


                                y: {

                                    beginAtZero: true,

                                    title: {

                                        display: true,

                                        text:
                                            "Production"

                                    }

                                }

                            }

                        }

                    }
                );

        }


        // ==================================================
        // GRAPHIQUE TEMPÉRATURE
        // ==================================================

        if (
            temperatureCanvas &&
            typeof Chart !== "undefined"
        ) {


            if (temperatureChart) {

                temperatureChart.destroy();

            }


            temperatureChart =
                new Chart(
                    temperatureCanvas,
                    {

                        type: "line",


                        data: {

                            labels: labels,


                            datasets: [

                                {

                                    label:
                                        "Température (°C)",

                                    data:
                                        temperatureValues,

                                    borderWidth: 3,

                                    tension: 0.3,

                                    fill: false,

                                    pointRadius: 4,

                                    pointHoverRadius: 7

                                },


                                {

                                    label:
                                        "Seuil alerte 70 °C",

                                    data:
                                        labels.map(
                                            () => 70
                                        ),

                                    borderWidth: 2,

                                    borderDash:
                                        [6, 6],

                                    pointRadius: 0,

                                    fill: false

                                }

                            ]

                        },


                        options: {

                            responsive: true,

                            maintainAspectRatio:
                                false,


                            interaction: {

                                mode: "index",

                                intersect: false

                            },


                            plugins: {

                                legend: {

                                    display: true,

                                    position: "top"

                                },


                                tooltip: {

                                    enabled: true

                                }

                            },


                            scales: {

                                x: {

                                    title: {

                                        display: true,

                                        text:
                                            "Date / heure"

                                    }

                                },


                                y: {

                                    beginAtZero:
                                        false,

                                    title: {

                                        display: true,

                                        text:
                                            "Température (°C)"

                                    }

                                }

                            }

                        }

                    }
                );

        }


        if (typeof Chart === "undefined") {

            console.error(
                "Chart.js n'est pas chargé."
            );

        }

    }


    // ======================================================
    // CHARGER LES DONNÉES DE PRODUCTION
    // ======================================================

    async function loadProduction() {


        const container =
            document.getElementById(
                "productionContainer"
            );


        const productionValue =
            document.getElementById(
                "productionValue"
            );


        const temperatureValue =
            document.getElementById(
                "temperatureValue"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des données
                de production...

            </p>

        `;


        try {


            const response =
                await fetch(
                    "/api/MachineData"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const data =
                await response.json();


            // =================================================
            // ACTUALISER LES GRAPHIQUES
            // =================================================

            createCharts(data);


            // =================================================
            // AUCUNE DONNÉE
            // =================================================

            if (
                !Array.isArray(data) ||
                data.length === 0
            ) {


                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucune donnée de
                            production enregistrée.

                        </p>

                    </div>

                `;


                if (productionValue) {

                    productionValue.textContent =
                        "0";

                }


                if (temperatureValue) {

                    temperatureValue.textContent =
                        "-- °C";

                }


                return;

            }


            // =================================================
            // DERNIÈRE MESURE
            // =================================================

            const latest =
                data[0];


            // =================================================
            // KPI PRODUCTION
            // =================================================

            if (productionValue) {

                productionValue.textContent =
                    latest.production ?? 0;

            }


            // =================================================
            // KPI TEMPÉRATURE
            // =================================================

            if (temperatureValue) {


                const temp =
                    latest.temperature;


                temperatureValue.textContent =

                    temp !== null &&
                    temp !== undefined

                        ? `${Number(temp)
                            .toFixed(1)} °C`

                        : "-- °C";

            }


            // =================================================
            // PAGE PRODUCTION
            // =================================================

            container.innerHTML = `

                <div class="production-summary">


                    <div class="production-summary-card">

                        <span>
                            🏭 Machine
                        </span>

                        <strong>

                            Machine ${
                                latest.machineId ??
                                "--"
                            }

                        </strong>

                    </div>


                    <div class="production-summary-card">

                        <span>
                            📦 Production actuelle
                        </span>

                        <strong>

                            ${
                                latest.production ??
                                0
                            }

                        </strong>

                    </div>


                    <div class="production-summary-card">

                        <span>
                            🌡️ Température
                        </span>

                        <strong>

                            ${
                                latest.temperature !==
                                    null &&
                                latest.temperature !==
                                    undefined

                                    ? Number(
                                        latest.temperature
                                      ).toFixed(1)
                                      + " °C"

                                    : "--"
                            }

                        </strong>

                    </div>


                    <div class="production-summary-card">

                        <span>
                            ⚙️ État
                        </span>

                        <strong>

                            ${
                                latest.etat ??
                                "INCONNU"
                            }

                        </strong>

                    </div>

                </div>


                <div class="panel">


                    <div class="panel-header">

                        <h3>
                            Historique des mesures
                        </h3>

                    </div>


                    <div class="table-wrapper">


                        <table class="data-table">


                            <thead>

                                <tr>

                                    <th>ID</th>

                                    <th>Machine</th>

                                    <th>Production</th>

                                    <th>Température</th>

                                    <th>État</th>

                                    <th>Aide</th>

                                    <th>Date</th>

                                </tr>

                            </thead>


                            <tbody>
                                                            ${
                                    data
                                    .slice(0, 50)
                                    .map(item => {


                                        const date =

                                            item.mqttTimestamp ||

                                            item.createdAt;


                                        const formattedDate =

                                            date

                                                ? new Date(
                                                    date
                                                  )
                                                  .toLocaleString(
                                                      "fr-FR"
                                                  )

                                                : "--";


                                        const aide =

                                            item.demandeAide

                                                ? "OUI"

                                                : "NON";


                                        return `

                                            <tr>


                                                <td>

                                                    ${
                                                        item.id ??
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    Machine ${
                                                        item.machineId ??
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        item.production ??
                                                        0
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        item.temperature !==
                                                            null &&
                                                        item.temperature !==
                                                            undefined

                                                            ? Number(
                                                                item.temperature
                                                              )
                                                              .toFixed(1)
                                                              + " °C"

                                                            : "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        item.etat ??
                                                        "INCONNU"
                                                    }

                                                </td>


                                                <td>

                                                    ${aide}

                                                </td>


                                                <td>

                                                    ${formattedDate}

                                                </td>


                                            </tr>

                                        `;

                                    })
                                    .join("")
                                }

                            </tbody>


                        </table>


                    </div>


                </div>

            `;

        }

        catch (error) {


            console.error(
                "Erreur chargement MachineData :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les données de production.

                    </p>

                </div>

            `;

        }

    }


    // ======================================================
    // CHARGER LES ALERTES
    // ======================================================

    async function loadAlerts() {

        const container =
            document.getElementById(
                "alertsContainer"
            );

        const recentAlerts =
            document.getElementById(
                "recentAlerts"
            );

        const alertCount =
            document.getElementById(
                "alertCount"
            );


        try {

            const response =
                await fetch(
                    "/api/Alerts"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );
            }


            const alerts =
                await response.json();


            // =================================================
            // KPI NOMBRE D'ALERTES
            // =================================================

            if (alertCount) {

                alertCount.textContent =
                    Array.isArray(alerts)
                        ? alerts.length
                        : "0";
            }


            // =================================================
            // AUCUNE ALERTE
            // =================================================

            if (
                !Array.isArray(alerts) ||
                alerts.length === 0
            ) {

                if (container) {

                    container.innerHTML = `

                        <div class="panel">

                            <p class="empty-message">
                                Aucune alerte enregistrée.
                            </p>

                        </div>
                    `;
                }


                if (recentAlerts) {

                    recentAlerts.innerHTML = `

                        <p class="empty-message">
                            Aucune alerte récente.
                        </p>
                    `;
                }


                return;
            }


            // =================================================
            // TYPE ET STYLE D'ALERTE
            // =================================================

            function getAlertStyle(type) {

                const normalizedType =
                    (type || "")
                        .toUpperCase();


                if (
                    normalizedType ===
                    "TEMPERATURE_ELEVEE"
                ) {

                    return {
                        icon: "🌡️",
                        className:
                            "alert-temperature"
                    };
                }


                if (
                    normalizedType ===
                    "ARRET_MACHINE"
                ) {

                    return {
                        icon: "🛑",
                        className:
                            "alert-stop"
                    };
                }


                if (
                    normalizedType ===
                    "DEMANDE_AIDE"
                ) {

                    return {
                        icon: "🆘",
                        className:
                            "alert-help"
                    };
                }


                return {
                    icon: "⚠️",
                    className:
                        "alert-default"
                };
            }


            // =================================================
            // PAGE ALERTES
            // =================================================

            if (container) {

                container.innerHTML = `

                    <div class="alerts-toolbar">

                        <div>

                            <label for="alertMachineFilter">
                                Machine
                            </label>

                            <select id="alertMachineFilter">

                                <option value="ALL">
                                    Toutes les machines
                                </option>

                                ${
                                    [
                                        ...new Set(
                                            alerts.map(
                                                alert =>
                                                    alert.machineId
                                            )
                                        )
                                    ]
                                    .sort(
                                        (a, b) => a - b
                                    )
                                    .map(
                                        machineId => `

                                            <option
                                                value="${machineId}"
                                            >

                                                Machine ${machineId}

                                            </option>

                                        `
                                    )
                                    .join("")
                                }

                            </select>

                        </div>


                        <div>

                            <label for="alertStatusFilter">
                                Statut
                            </label>

                            <select id="alertStatusFilter">

                                <option value="ALL">
                                    Tous les statuts
                                </option>

                                ${
                                    [
                                        ...new Set(
                                            alerts.map(
                                                alert =>
                                                    (
                                                        alert.statut ||
                                                        "INCONNU"
                                                    ).toUpperCase()
                                            )
                                        )
                                    ]
                                    .map(
                                        statut => `

                                            <option value="${statut}">
                                                ${statut}
                                            </option>

                                        `
                                    )
                                    .join("")
                                }

                            </select>

                        </div>

                    </div>


                    <div id="alertsList"></div>
                `;


                const alertsList =
                    document.getElementById(
                        "alertsList"
                    );

                const machineFilter =
                    document.getElementById(
                        "alertMachineFilter"
                    );

                const statusFilter =
                    document.getElementById(
                        "alertStatusFilter"
                    );


                function renderAlerts() {

                    if (!alertsList) {

                        return;
                    }


                    const selectedMachine =
                        machineFilter
                            ? machineFilter.value
                            : "ALL";


                    const selectedStatus =
                        statusFilter
                            ? statusFilter.value
                            : "ALL";


                    const filteredAlerts =
                        alerts.filter(alert => {

                            const machineOk =
                                selectedMachine ===
                                    "ALL" ||
                                String(
                                    alert.machineId
                                ) ===
                                    selectedMachine;


                            const status =
                                (
                                    alert.statut ||
                                    "INCONNU"
                                ).toUpperCase();


                            const statusOk =
                                selectedStatus ===
                                    "ALL" ||
                                status ===
                                    selectedStatus;


                            return (
                                machineOk &&
                                statusOk
                            );

                        });


                    if (
                        filteredAlerts.length === 0
                    ) {

                        alertsList.innerHTML = `

                            <div class="panel">

                                <p class="empty-message">

                                    Aucune alerte ne correspond
                                    aux filtres sélectionnés.

                                </p>

                            </div>

                        `;

                        return;
                    }


                    alertsList.innerHTML =
                        filteredAlerts
                        .map(alert => {

                            const style =
                                getAlertStyle(
                                    alert.type
                                );


                            const date =
                                alert.dateHeure

                                    ? new Date(
                                        alert.dateHeure
                                      )
                                      .toLocaleString(
                                          "fr-FR"
                                      )

                                    : "--";


                            const statut =
                                (
                                    alert.statut ||
                                    "INCONNU"
                                ).toUpperCase();


                            return `

                                <div
                                    class="
                                        alert-card
                                        ${style.className}
                                    "
                                >

                                    <div
                                        class="
                                            alert-card-icon
                                        "
                                    >

                                        ${style.icon}

                                    </div>


                                    <div
                                        class="
                                            alert-card-content
                                        "
                                    >

                                        <div
                                            class="
                                                alert-card-header
                                            "
                                        >

                                            <div>

                                                <h3>

                                                    ${
                                                        alert.type ||
                                                        "ALERTE"
                                                    }

                                                </h3>


                                                <p>

                                                    Machine ${
                                                        alert.machineId ??
                                                        "--"
                                                    }

                                                </p>

                                            </div>


                                            <span
                                                class="
                                                    alert-status
                                                    ${
                                                        statut ===
                                                        "ACTIVE"

                                                            ? "alert-status-active"

                                                            : "alert-status-other"
                                                    }
                                                "
                                            >

                                                ${statut}

                                            </span>

                                        </div>


                                        <p
                                            class="
                                                alert-message
                                            "
                                        >

                                            ${
                                                alert.message ||
                                                "Aucun message."
                                            }

                                        </p>


                                        <div
                                            class="
                                                alert-meta
                                            "
                                        >

                                            <span>

                                                #${
                                                    alert.id ??
                                                    "--"
                                                }

                                            </span>


                                            <span>

                                                ${date}

                                            </span>

                                        </div>

                                    </div>

                                </div>

                            `;

                        })
                        .join("");

                }


                // =============================================
                // FILTRE MACHINE
                // =============================================

                if (machineFilter) {

                    machineFilter
                        .addEventListener(
                            "change",
                            renderAlerts
                        );
                }


                // =============================================
                // FILTRE STATUT
                // =============================================

                if (statusFilter) {

                    statusFilter
                        .addEventListener(
                            "change",
                            renderAlerts
                        );
                }


                renderAlerts();

            }


            // =================================================
            // ALERTES RÉCENTES DU DASHBOARD
            // =================================================

            if (recentAlerts) {

                recentAlerts.innerHTML =
                    alerts
                    .slice(0, 5)
                    .map(alert => {

                        const style =
                            getAlertStyle(
                                alert.type
                            );


                        const date =
                            alert.dateHeure

                                ? new Date(
                                    alert.dateHeure
                                  )
                                  .toLocaleString(
                                      "fr-FR"
                                  )

                                : "--";


                        return `

                            <div
                                class="
                                    recent-alert-item
                                    ${style.className}
                                "
                            >

                                <div
                                    class="
                                        recent-alert-icon
                                    "
                                >

                                    ${style.icon}

                                </div>


                                <div
                                    class="
                                        recent-alert-content
                                    "
                                >

                                    <strong>

                                        ${
                                            alert.type ||
                                            "ALERTE"
                                        }

                                    </strong>


                                    <span>

                                        Machine ${
                                            alert.machineId ??
                                            "--"
                                        }

                                        •

                                        ${date}

                                    </span>

                                </div>


                                <span
                                    class="
                                        recent-alert-status
                                    "
                                >

                                    ${
                                        (
                                            alert.statut ||
                                            "INCONNU"
                                        ).toUpperCase()
                                    }

                                </span>

                            </div>

                        `;

                    })
                    .join("");
            }

        }

        catch (error) {

            console.error(
                "Erreur chargement Alertes :",
                error
            );


            if (container) {

                container.innerHTML = `

                    <div class="panel">

                        <p style="color:#e53935;">

                            Impossible de charger
                            les alertes.

                        </p>

                    </div>

                `;
            }


            if (recentAlerts) {

                recentAlerts.innerHTML = `

                    <p style="color:#e53935;">

                        Impossible de charger
                        les alertes récentes.

                    </p>

                `;
            }


            if (alertCount) {

                alertCount.textContent = "!";

            }

        }

    }



    // ======================================================
    // CHARGER LES NOTIFICATIONS
    // ======================================================

    async function loadNotifications() {

        const container =
            document.getElementById(
                "notificationsContainer"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des notifications...

            </p>

        `;


        try {

            const response =
                await fetch(
                    "/api/Notifications"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const notifications =
                await response.json();


            // =================================================
            // AUCUNE NOTIFICATION
            // =================================================

            if (
                !Array.isArray(notifications) ||
                notifications.length === 0
            ) {

                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucune notification enregistrée.

                        </p>

                    </div>

                `;

                return;

            }


            // =================================================
            // BARRE DE FILTRES
            // =================================================

            container.innerHTML = `

                <div class="notifications-toolbar">


                    <div>

                        <label for="notificationStatusFilter">

                            Statut

                        </label>


                        <select id="notificationStatusFilter">

                            <option value="ALL">

                                Tous les statuts

                            </option>


                            ${
                                [
                                    ...new Set(
                                        notifications.map(
                                            notification =>
                                                (
                                                    notification.statut ||
                                                    "INCONNU"
                                                ).toUpperCase()
                                        )
                                    )
                                ]
                                .sort()
                                .map(
                                    statut => `

                                        <option value="${statut}">

                                            ${statut}

                                        </option>

                                    `
                                )
                                .join("")
                            }

                        </select>

                    </div>


                    <div>

                        <label for="notificationChannelFilter">

                            Canal

                        </label>


                        <select id="notificationChannelFilter">

                            <option value="ALL">

                                Tous les canaux

                            </option>


                            ${
                                [
                                    ...new Set(
                                        notifications.map(
                                            notification =>
                                                (
                                                    notification.canal ||
                                                    "INCONNU"
                                                ).toUpperCase()
                                        )
                                    )
                                ]
                                .sort()
                                .map(
                                    canal => `

                                        <option value="${canal}">

                                            ${canal}

                                        </option>

                                    `
                                )
                                .join("")
                            }

                        </select>

                    </div>

                </div>


                <div id="notificationsList"></div>

            `;


            const list =
                document.getElementById(
                    "notificationsList"
                );


            const statusFilter =
                document.getElementById(
                    "notificationStatusFilter"
                );


            const channelFilter =
                document.getElementById(
                    "notificationChannelFilter"
                );


            // =================================================
            // STYLE SELON LE STATUT
            // =================================================

            function getNotificationStyle(statut) {

                const normalizedStatus =
                    (statut || "")
                        .toUpperCase();


                if (
                    normalizedStatus ===
                    "ENVOYEE"
                ) {

                    return {

                        icon: "✅",

                        className:
                            "notification-sent",

                        badgeClass:
                            "notification-status-sent"

                    };

                }


                if (
                    normalizedStatus ===
                    "ECHEC"
                ) {

                    return {

                        icon: "❌",

                        className:
                            "notification-failed",

                        badgeClass:
                            "notification-status-failed"

                    };

                }


                return {

                    icon: "⏳",

                    className:
                        "notification-pending",

                    badgeClass:
                        "notification-status-pending"

                };

            }


            // =================================================
            // AFFICHAGE DES NOTIFICATIONS
            // =================================================

            function renderNotifications() {

                if (!list) {

                    return;

                }


                const selectedStatus =
                    statusFilter
                        ? statusFilter.value
                        : "ALL";


                const selectedChannel =
                    channelFilter
                        ? channelFilter.value
                        : "ALL";


                const filteredNotifications =
                    notifications.filter(
                        notification => {


                            const statut =
                                (
                                    notification.statut ||
                                    "INCONNU"
                                ).toUpperCase();


                            const canal =
                                (
                                    notification.canal ||
                                    "INCONNU"
                                ).toUpperCase();


                            const statusOk =
                                selectedStatus ===
                                    "ALL" ||
                                statut ===
                                    selectedStatus;


                            const channelOk =
                                selectedChannel ===
                                    "ALL" ||
                                canal ===
                                    selectedChannel;


                            return (
                                statusOk &&
                                channelOk
                            );

                        }
                    );


                if (
                    filteredNotifications.length === 0
                ) {

                    list.innerHTML = `

                        <div class="panel">

                            <p class="empty-message">

                                Aucune notification ne correspond
                                aux filtres sélectionnés.

                            </p>

                        </div>

                    `;

                    return;

                }


                list.innerHTML =
                    filteredNotifications
                    .map(notification => {


                        const statut =
                            (
                                notification.statut ||
                                "INCONNU"
                            ).toUpperCase();


                        const canal =
                            (
                                notification.canal ||
                                "INCONNU"
                            ).toUpperCase();


                        const style =
                            getNotificationStyle(
                                statut
                            );


                        const createdAt =
                            notification.createdAt

                                ? new Date(
                                    notification.createdAt
                                  )
                                  .toLocaleString(
                                      "fr-FR"
                                  )

                                : "--";


                        const dateEnvoi =
                            notification.dateEnvoi

                                ? new Date(
                                    notification.dateEnvoi
                                  )
                                  .toLocaleString(
                                      "fr-FR"
                                  )

                                : "Non envoyée";


                        return `

                            <div
                                class="
                                    notification-card
                                    ${style.className}
                                "
                            >

                                <div
                                    class="
                                        notification-card-icon
                                    "
                                >

                                    ${style.icon}

                                </div>


                                <div
                                    class="
                                        notification-card-content
                                    "
                                >

                                    <div
                                        class="
                                            notification-card-header
                                        "
                                    >

                                        <div>

                                            <h3>

                                                Notification #${
                                                    notification.id ??
                                                    "--"
                                                }

                                            </h3>

                                            <p>

                                                Alerte #${
                                                    notification.alertId ??
                                                    "--"
                                                }

                                            </p>

                                        </div>


                                        <span
                                            class="
                                                notification-status
                                                ${style.badgeClass}
                                            "
                                        >

                                            ${statut}

                                        </span>

                                    </div>


                                    <div
                                        class="
                                            notification-details
                                        "
                                    >

                                        <div>

                                            <span>
                                                Destinataire
                                            </span>

                                            <strong>

                                                ${
                                                    notification.destinataire ||
                                                    "--"
                                                }

                                            </strong>

                                        </div>


                                        <div>

                                            <span>
                                                Canal
                                            </span>

                                            <strong>

                                                ${canal}

                                            </strong>

                                        </div>


                                        <div>

                                            <span>
                                                Date d'envoi
                                            </span>

                                            <strong>

                                                ${dateEnvoi}

                                            </strong>

                                        </div>


                                        <div>

                                            <span>
                                                Créée le
                                            </span>

                                            <strong>

                                                ${createdAt}

                                            </strong>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        `;

                    })
                    .join("");

            }


            // =================================================
            // FILTRE STATUT
            // =================================================

            if (statusFilter) {

                statusFilter
                    .addEventListener(
                        "change",
                        renderNotifications
                    );

            }


            // =================================================
            // FILTRE CANAL
            // =================================================

            if (channelFilter) {

                channelFilter
                    .addEventListener(
                        "change",
                        renderNotifications
                    );

            }


            // Premier affichage

            renderNotifications();

        }

        catch (error) {

            console.error(
                "Erreur chargement Notifications :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les notifications.

                    </p>

                </div>

            `;

        }

    }
        // ======================================================
    // CHARGER LES INTERVENTIONS MAINTENANCE
    // ADMIN WEB : CONSULTATION UNIQUEMENT
    // ======================================================

    async function loadInterventions() {

        const container =
            document.getElementById(
                "interventionsContainer"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des interventions...

            </p>

        `;


        try {

            const response =
                await fetch(
                    "/api/Interventions"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const interventions =
                await response.json();


            // =================================================
            // AUCUNE INTERVENTION
            // =================================================

            if (
                !Array.isArray(interventions) ||
                interventions.length === 0
            ) {

                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucune intervention enregistrée.

                        </p>

                    </div>

                `;

                return;

            }


            // =================================================
            // TRIER PAR DATE : PLUS RÉCENTE EN PREMIER
            // =================================================

            const sortedInterventions =
                [...interventions].sort(
                    (a, b) => {

                        const dateA =
                            a.dateIntervention

                                ? new Date(
                                    a.dateIntervention
                                  )

                                : new Date(0);


                        const dateB =
                            b.dateIntervention

                                ? new Date(
                                    b.dateIntervention
                                  )

                                : new Date(0);


                        return dateB - dateA;

                    }
                );


            // =================================================
            // AFFICHAGE
            // =================================================

            container.innerHTML = `

                <div class="panel">


                    <div class="panel-header">

                        <h3>

                            Historique des interventions

                        </h3>

                    </div>


                    <div class="table-wrapper">


                        <table class="data-table">


                            <thead>

                                <tr>

                                    <th>ID</th>

                                    <th>Alerte</th>

                                    <th>Machine</th>

                                    <th>Technicien</th>

                                    <th>Résultat</th>

                                    <th>Commentaire</th>

                                    <th>Date</th>

                                </tr>

                            </thead>


                            <tbody>

                                ${
                                    sortedInterventions
                                    .map(
                                        intervention => {


                                            const resultat =
                                                (
                                                    intervention.resultat ||
                                                    "INCONNU"
                                                ).toUpperCase();


                                            const date =
                                                intervention.dateIntervention

                                                    ? new Date(
                                                        intervention.dateIntervention
                                                      )
                                                      .toLocaleString(
                                                          "fr-FR"
                                                      )

                                                    : "--";


                                            let resultatLabel =
                                                resultat;


                                            if (
                                                resultat ===
                                                "RESOLUE"
                                            ) {

                                                resultatLabel =
                                                    "🟢 Panne résolue";

                                            }

                                            else if (
                                                resultat ===
                                                "PANNE_MAJEURE"
                                            ) {

                                                resultatLabel =
                                                    "🔴 Panne majeure";

                                            }


                                            const commentaire =

                                                intervention.commentaire &&
                                                intervention.commentaire
                                                    .trim() !== ""

                                                    ? intervention.commentaire

                                                    : "Aucun commentaire";


                                            return `

                                                <tr>


                                                    <td>

                                                        ${
                                                            intervention.id ??
                                                            "--"
                                                        }

                                                    </td>


                                                    <td>

                                                        #${
                                                            intervention.alertId ??
                                                            "--"
                                                        }

                                                    </td>


                                                    <td>

                                                        Machine ${
                                                            intervention.machineId ??
                                                            "--"
                                                        }

                                                    </td>


                                                    <td>

                                                        ${
                                                            intervention.technicien ||
                                                            "--"
                                                        }

                                                    </td>


                                                    <td>

                                                        ${resultatLabel}

                                                    </td>


                                                    <td>

                                                        ${commentaire}

                                                    </td>


                                                    <td>

                                                        ${date}

                                                    </td>


                                                </tr>

                                            `;

                                        }
                                    )
                                    .join("")
                                }

                            </tbody>


                        </table>


                    </div>


                </div>

            `;

        }

        catch (error) {

            console.error(
                "Erreur chargement Interventions :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les interventions.

                    </p>

                </div>

            `;

        }

    }



    // ======================================================
    // CHARGER LES COMMANDES
    // ======================================================

    async function loadCommands() {

        const container =
            document.getElementById(
                "commandsContainer"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des commandes...

            </p>

        `;


        try {

            const response =
                await fetch(
                    "/api/Commands"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const commands =
                await response.json();


            // =================================================
            // AUCUNE COMMANDE
            // =================================================

            if (
                !Array.isArray(commands) ||
                commands.length === 0
            ) {

                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucune commande enregistrée.

                        </p>

                    </div>

                `;

                return;

            }


            // =================================================
            // FILTRES
            // =================================================

            container.innerHTML = `

                <div class="commands-toolbar">


                    <div>

                        <label for="commandMachineFilter">

                            Machine

                        </label>


                        <select id="commandMachineFilter">

                            <option value="ALL">

                                Toutes les machines

                            </option>


                            ${
                                [
                                    ...new Set(
                                        commands.map(
                                            command =>
                                                command.machineId
                                        )
                                    )
                                ]
                                .sort(
                                    (a, b) => a - b
                                )
                                .map(
                                    machineId => `

                                        <option
                                            value="${machineId}"
                                        >

                                            Machine ${machineId}

                                        </option>

                                    `
                                )
                                .join("")
                            }

                        </select>

                    </div>


                    <div>

                        <label for="commandStatusFilter">

                            Statut

                        </label>


                        <select id="commandStatusFilter">

                            <option value="ALL">

                                Tous les statuts

                            </option>


                            ${
                                [
                                    ...new Set(
                                        commands.map(
                                            command =>
                                                (
                                                    command.statut ||
                                                    "INCONNU"
                                                ).toUpperCase()
                                        )
                                    )
                                ]
                                .sort()
                                .map(
                                    statut => `

                                        <option value="${statut}">

                                            ${statut}

                                        </option>

                                    `
                                )
                                .join("")
                            }

                        </select>

                    </div>


                    <div>

                        <label for="commandSourceFilter">

                            Source

                        </label>


                        <select id="commandSourceFilter">

                            <option value="ALL">

                                Toutes les sources

                            </option>


                            ${
                                [
                                    ...new Set(
                                        commands.map(
                                            command =>
                                                (
                                                    command.source ||
                                                    "INCONNU"
                                                ).toUpperCase()
                                        )
                                    )
                                ]
                                .sort()
                                .map(
                                    source => `

                                        <option value="${source}">

                                            ${source}

                                        </option>

                                    `
                                )
                                .join("")
                            }

                        </select>

                    </div>


                </div>


                <div id="commandsList"></div>

            `;


            const list =
                document.getElementById(
                    "commandsList"
                );


            const machineFilter =
                document.getElementById(
                    "commandMachineFilter"
                );


            const statusFilter =
                document.getElementById(
                    "commandStatusFilter"
                );


            const sourceFilter =
                document.getElementById(
                    "commandSourceFilter"
                );


            // =================================================
            // STYLE SELON STATUT COMMANDE
            // =================================================

            function getCommandStyle(statut) {

                const normalizedStatus =
                    (statut || "")
                        .toUpperCase();


                if (
                    normalizedStatus ===
                    "EXECUTEE"
                ) {

                    return {

                        icon: "✅",

                        className:
                            "command-success",

                        badgeClass:
                            "command-status-success"

                    };

                }


                if (
                    normalizedStatus ===
                    "EN_ATTENTE"
                ) {

                    return {

                        icon: "⏳",

                        className:
                            "command-pending",

                        badgeClass:
                            "command-status-pending"

                    };

                }


                if (
                    normalizedStatus ===
                    "ECHEC"
                ) {

                    return {

                        icon: "❌",

                        className:
                            "command-failed",

                        badgeClass:
                            "command-status-failed"

                    };

                }


                return {

                    icon: "🎮",

                    className:
                        "command-default",

                    badgeClass:
                        "command-status-default"

                };

            }


            // =================================================
            // AFFICHAGE DES COMMANDES
            // =================================================

            function renderCommands() {

                if (!list) {

                    return;

                }


                const selectedMachine =
                    machineFilter

                        ? machineFilter.value

                        : "ALL";


                const selectedStatus =
                    statusFilter

                        ? statusFilter.value

                        : "ALL";


                const selectedSource =
                    sourceFilter

                        ? sourceFilter.value

                        : "ALL";


                const filteredCommands =
                    commands.filter(
                        command => {


                            const statut =
                                (
                                    command.statut ||
                                    "INCONNU"
                                ).toUpperCase();


                            const source =
                                (
                                    command.source ||
                                    "INCONNU"
                                ).toUpperCase();


                            const machineOk =
                                selectedMachine ===
                                    "ALL" ||

                                String(
                                    command.machineId
                                ) ===
                                    selectedMachine;


                            const statusOk =
                                selectedStatus ===
                                    "ALL" ||

                                statut ===
                                    selectedStatus;


                            const sourceOk =
                                selectedSource ===
                                    "ALL" ||

                                source ===
                                    selectedSource;


                            return (
                                machineOk &&
                                statusOk &&
                                sourceOk
                            );

                        }
                    );


                if (
                    filteredCommands.length === 0
                ) {

                    list.innerHTML = `

                        <div class="panel">

                            <p class="empty-message">

                                Aucune commande ne correspond
                                aux filtres sélectionnés.

                            </p>

                        </div>

                    `;

                    return;

                }


                list.innerHTML =
                    filteredCommands
                    .map(command => {


                        const statut =
                            (
                                command.statut ||
                                "INCONNU"
                            ).toUpperCase();


                        const source =
                            (
                                command.source ||
                                "INCONNU"
                            ).toUpperCase();


                        const style =
                            getCommandStyle(
                                statut
                            );


                        const createdAt =
                            command.createdAt

                                ? new Date(
                                    command.createdAt
                                  )
                                  .toLocaleString(
                                      "fr-FR"
                                  )

                                : "--";


                        const updatedAt =
                            command.updatedAt

                                ? new Date(
                                    command.updatedAt
                                  )
                                  .toLocaleString(
                                      "fr-FR"
                                  )

                                : "--";


                        return `

                            <div
                                class="
                                    command-card
                                    ${style.className}
                                "
                            >


                                <div
                                    class="
                                        command-card-icon
                                    "
                                >

                                    ${style.icon}

                                </div>


                                <div
                                    class="
                                        command-card-content
                                    "
                                >


                                    <div
                                        class="
                                            command-card-header
                                        "
                                    >


                                        <div>

                                            <h3>

                                                ${
                                                    command.commande ||
                                                    command.command ||
                                                    "Commande"
                                                }

                                            </h3>


                                            <p>

                                                Machine ${
                                                    command.machineId ??
                                                    "--"
                                                }

                                            </p>

                                        </div>


                                        <span
                                            class="
                                                command-status
                                                ${style.badgeClass}
                                            "
                                        >

                                            ${statut}

                                        </span>


                                    </div>


                                    <div
                                        class="
                                            command-details
                                        "
                                    >


                                        <div>

                                            <span>

                                                ID

                                            </span>

                                            <strong>

                                                #${
                                                    command.id ??
                                                    "--"
                                                }

                                            </strong>

                                        </div>


                                        <div>

                                            <span>

                                                Utilisateur

                                            </span>

                                            <strong>

                                                ${
                                                    command.userId ??
                                                    command.utilisateurId ??
                                                    "--"
                                                }

                                            </strong>

                                        </div>


                                        <div>

                                            <span>

                                                Source

                                            </span>

                                            <strong>

                                                ${source}

                                            </strong>

                                        </div>


                                        <div>

                                            <span>

                                                Créée le

                                            </span>

                                            <strong>

                                                ${createdAt}

                                            </strong>

                                        </div>


                                        <div>

                                            <span>

                                                Mise à jour

                                            </span>

                                            <strong>

                                                ${updatedAt}

                                            </strong>

                                        </div>


                                    </div>


                                </div>


                            </div>

                        `;

                    })
                    .join("");

            }


            // =================================================
            // FILTRE MACHINE
            // =================================================

            if (machineFilter) {

                machineFilter
                    .addEventListener(
                        "change",
                        renderCommands
                    );

            }


            // =================================================
            // FILTRE STATUT
            // =================================================

            if (statusFilter) {

                statusFilter
                    .addEventListener(
                        "change",
                        renderCommands
                    );

            }


            // =================================================
            // FILTRE SOURCE
            // =================================================

            if (sourceFilter) {

                sourceFilter
                    .addEventListener(
                        "change",
                        renderCommands
                    );

            }


            // Premier affichage

            renderCommands();

        }

        catch (error) {

            console.error(
                "Erreur chargement Commandes :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les commandes.

                    </p>

                </div>

            `;

        }

    }
        // ======================================================
    // CHARGER LES UTILISATEURS
    // ======================================================

    async function loadUsers() {

        const container =
            document.getElementById(
                "usersContainer"
            );


        if (!container) {

            return;

        }


        container.innerHTML = `

            <p class="empty-message">

                Chargement des utilisateurs...

            </p>

        `;


        try {

            const response =
                await fetch(
                    "/api/Users"
                );


            if (!response.ok) {

                throw new Error(
                    `Erreur HTTP : ${response.status}`
                );

            }


            const users =
                await response.json();


            // =================================================
            // AUCUN UTILISATEUR
            // =================================================

            if (
                !Array.isArray(users) ||
                users.length === 0
            ) {

                container.innerHTML = `

                    <div class="panel">

                        <p class="empty-message">

                            Aucun utilisateur enregistré.

                        </p>

                    </div>

                `;

                return;

            }


            // =================================================
            // AFFICHAGE DES UTILISATEURS
            // ADMIN WEB : CONSULTATION
            // =================================================

            container.innerHTML = `

                <div class="panel">


                    <div class="panel-header">

                        <h3>

                            Utilisateurs ProdMon

                        </h3>

                    </div>


                    <div class="table-wrapper">


                        <table class="data-table">


                            <thead>

                                <tr>

                                    <th>ID</th>

                                    <th>Nom utilisateur</th>

                                    <th>Email</th>

                                    <th>Rôle</th>

                                    <th>État</th>

                                </tr>

                            </thead>


                            <tbody>

                                ${
                                    users
                                    .map(user => {


                                        const isActive =
                                            user.isActive === true ||
                                            user.is_active === true;


                                        const activeLabel =
                                            isActive

                                                ? "🟢 Actif"

                                                : "🔴 Inactif";


                                        return `

                                            <tr>


                                                <td>

                                                    ${
                                                        user.id ??
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        user.username ||
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        user.email ||
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${
                                                        user.role ||
                                                        "--"
                                                    }

                                                </td>


                                                <td>

                                                    ${activeLabel}

                                                </td>


                                            </tr>

                                        `;

                                    })
                                    .join("")
                                }

                            </tbody>


                        </table>


                    </div>


                </div>

            `;

        }

        catch (error) {

            console.error(
                "Erreur chargement Utilisateurs :",
                error
            );


            container.innerHTML = `

                <div class="panel">

                    <p style="color:#e53935;">

                        Impossible de charger
                        les utilisateurs.

                    </p>

                </div>

            `;

        }

    }



    // ======================================================
    // ANALYSES / TRS - OEE
    // ======================================================

    async function loadAnalytics() {


        const availabilityValue =
            document.getElementById(
                "availabilityValue"
            );


        const performanceValue =
            document.getElementById(
                "performanceValue"
            );


        const qualityValue =
            document.getElementById(
                "qualityValue"
            );


        const oeeValue =
            document.getElementById(
                "oeeValue"
            );


        const analyticsProduction =
            document.getElementById(
                "analyticsProduction"
            );


        const analyticsTemperature =
            document.getElementById(
                "analyticsTemperature"
            );


        const analyticsAlerts =
            document.getElementById(
                "analyticsAlerts"
            );


        const analyticsSamples =
            document.getElementById(
                "analyticsSamples"
            );


        const interpretation =
            document.getElementById(
                "oeeInterpretation"
            );


        const machineFilter =
            document.getElementById(
                "analyticsMachineFilter"
            );


        const targetInput =
            document.getElementById(
                "targetProduction"
            );


        try {


            // =================================================
            // CHARGEMENT DES DONNÉES
            // =================================================

            const [
                machineResponse,
                dataResponse,
                alertResponse
            ] = await Promise.all([

                fetch("/api/Machines"),

                fetch("/api/MachineData"),

                fetch("/api/Alerts")

            ]);


            if (
                !machineResponse.ok ||
                !dataResponse.ok ||
                !alertResponse.ok
            ) {

                throw new Error(
                    "Impossible de charger les données d'analyse."
                );

            }


            const machines =
                await machineResponse.json();


            const machineData =
                await dataResponse.json();


            const alerts =
                await alertResponse.json();


            // =================================================
            // REMPLIR LE FILTRE MACHINE
            // =================================================

            if (machineFilter) {


                const previousValue =
                    machineFilter.value;


                machineFilter.innerHTML = `

                    <option value="ALL">

                        Toutes les machines

                    </option>

                    ${
                        Array.isArray(machines)

                            ? machines
                                .map(machine => `

                                    <option
                                        value="${machine.id}"
                                    >

                                        ${
                                            machine.nom ||
                                            `Machine ${machine.id}`
                                        }

                                    </option>

                                `)
                                .join("")

                            : ""
                    }

                `;


                // Conserver le choix si possible

                const optionExists =
                    Array.from(
                        machineFilter.options
                    )
                    .some(
                        option =>
                            option.value ===
                            previousValue
                    );


                if (optionExists) {

                    machineFilter.value =
                        previousValue;

                }

            }


            // =================================================
            // MACHINE SÉLECTIONNÉE
            // =================================================

            const selectedMachine =
                machineFilter
                    ? machineFilter.value
                    : "ALL";


            // =================================================
            // FILTRER LES MESURES
            // =================================================

            const filteredData =
                Array.isArray(machineData)

                    ? machineData.filter(
                        item => {

                            if (
                                selectedMachine ===
                                "ALL"
                            ) {

                                return true;

                            }


                            return (
                                String(
                                    item.machineId
                                ) ===
                                selectedMachine
                            );

                        }
                    )

                    : [];


            // =================================================
            // FILTRER LES ALERTES
            // =================================================

            const filteredAlerts =
                Array.isArray(alerts)

                    ? alerts.filter(
                        alert => {

                            if (
                                selectedMachine ===
                                "ALL"
                            ) {

                                return true;

                            }


                            return (
                                String(
                                    alert.machineId
                                ) ===
                                selectedMachine
                            );

                        }
                    )

                    : [];


            // =================================================
            // NOMBRE DE MESURES
            // =================================================

            const sampleCount =
                filteredData.length;


            if (analyticsSamples) {

                analyticsSamples.textContent =
                    sampleCount;

            }


            // =================================================
            // AUCUNE MESURE
            // =================================================

            if (sampleCount === 0) {


                if (availabilityValue) {

                    availabilityValue.textContent =
                        "-- %";

                }


                if (performanceValue) {

                    performanceValue.textContent =
                        "-- %";

                }


                if (qualityValue) {

                    qualityValue.textContent =
                        "100 %";

                }


                if (oeeValue) {

                    oeeValue.textContent =
                        "-- %";

                }


                if (analyticsProduction) {

                    analyticsProduction.textContent =
                        "--";

                }


                if (analyticsTemperature) {

                    analyticsTemperature.textContent =
                        "-- °C";

                }


                if (analyticsAlerts) {

                    analyticsAlerts.textContent =
                        filteredAlerts.length;

                }


                if (interpretation) {

                    interpretation.innerHTML = `

                        Aucune mesure disponible
                        pour la sélection actuelle.

                    `;

                }


                updateMachineStateChart([]);

                updateAlertTypeChart(
                    filteredAlerts
                );


                return;

            }


            // =================================================
            // DISPONIBILITÉ
            //
            // Prototype :
            // proportion des mesures RUNNING
            // =================================================

            const runningCount =
                filteredData.filter(
                    item =>
                        (
                            item.etat ||
                            ""
                        ).toUpperCase() ===
                        "RUNNING"
                ).length;


            const availability =
                sampleCount > 0

                    ? (
                        runningCount /
                        sampleCount
                      ) * 100

                    : 0;


            // =================================================
            // PRODUCTION MAXIMALE OBSERVÉE
            // =================================================

            const productions =
                filteredData
                .map(
                    item =>
                        Number(
                            item.production ??
                            0
                        )
                )
                .filter(
                    value =>
                        !Number.isNaN(value)
                );


            const maxProduction =
                productions.length > 0

                    ? Math.max(
                        ...productions
                      )

                    : 0;


            // =================================================
            // PRODUCTION CIBLE
            // =================================================

            let targetProduction =
                targetInput

                    ? Number(
                        targetInput.value
                      )

                    : 150;


            if (
                !Number.isFinite(
                    targetProduction
                ) ||
                targetProduction <= 0
            ) {

                targetProduction = 150;

            }


            // =================================================
            // PERFORMANCE
            //
            // Production max observée / cible
            // Limitée à 100 %
            // =================================================

            const performance =
                Math.min(
                    (
                        maxProduction /
                        targetProduction
                    ) * 100,
                    100
                );


            // =================================================
            // QUALITÉ
            //
            // Hypothèse prototype = 100 %
            // =================================================

            const quality = 100;


            // =================================================
            // TRS / OEE
            // =================================================

            const oee =
                (
                    availability /
                    100
                ) *

                (
                    performance /
                    100
                ) *

                (
                    quality /
                    100
                ) *

                100;


            // =================================================
            // TEMPÉRATURE MOYENNE
            // =================================================

            const temperatures =
                filteredData

                    .map(
                        item =>
                            item.temperature
                    )

                    .filter(
                        value =>
                            value !== null &&
                            value !== undefined &&
                            !Number.isNaN(
                                Number(value)
                            )
                    )

                    .map(
                        value =>
                            Number(value)
                    );


            const averageTemperature =
                temperatures.length > 0

                    ? temperatures.reduce(
                        (sum, value) =>
                            sum + value,
                        0
                      ) /
                      temperatures.length

                    : null;


            // =================================================
            // AFFICHAGE KPI
            // =================================================

            if (availabilityValue) {

                availabilityValue.textContent =
                    `${availability.toFixed(1)} %`;

            }


            if (performanceValue) {

                performanceValue.textContent =
                    `${performance.toFixed(1)} %`;

            }


            if (qualityValue) {

                qualityValue.textContent =
                    `${quality.toFixed(0)} %`;

            }


            if (oeeValue) {

                oeeValue.textContent =
                    `${oee.toFixed(1)} %`;

            }


            if (analyticsProduction) {

                analyticsProduction.textContent =
                    maxProduction;

            }


            if (analyticsTemperature) {

                analyticsTemperature.textContent =

                    averageTemperature !== null

                        ? `${averageTemperature
                            .toFixed(1)} °C`

                        : "-- °C";

            }


            if (analyticsAlerts) {

                analyticsAlerts.textContent =
                    filteredAlerts.length;

            }


            // =================================================
            // INTERPRÉTATION
            // =================================================

            if (interpretation) {


                let availabilityText = "";


                if (availability >= 90) {

                    availabilityText =
                        "La disponibilité estimée est élevée.";

                }

                else if (
                    availability >= 70
                ) {

                    availabilityText =
                        "La disponibilité estimée est moyenne.";

                }

                else {

                    availabilityText =
                        "La disponibilité estimée est faible.";

                }


                let performanceText = "";


                if (performance >= 90) {

                    performanceText =
                        "La production observée est proche de la cible.";

                }

                else if (
                    performance >= 70
                ) {

                    performanceText =
                        "La production observée reste inférieure à la cible.";

                }

                else {

                    performanceText =
                        "La production observée est nettement inférieure à la cible.";

                }


                interpretation.innerHTML = `

                    <strong>
                        TRS / OEE estimé :
                        ${oee.toFixed(1)} %
                    </strong>

                    <br><br>

                    ${availabilityText}

                    <br>

                    ${performanceText}

                    <br><br>

                    <em>

                        La qualité est fixée à 100 %
                        dans ce prototype car le système
                        ne mesure pas encore les pièces
                        conformes et les pièces rebutées.

                    </em>

                `;

            }


            // =================================================
            // GRAPHIQUES ANALYSES
            // =================================================

            updateMachineStateChart(
                filteredData
            );


            updateAlertTypeChart(
                filteredAlerts
            );

        }

        catch (error) {

            console.error(
                "Erreur chargement Analyses :",
                error
            );


            if (interpretation) {

                interpretation.innerHTML = `

                    <span style="color:#e53935;">

                        Impossible de charger
                        les données d'analyse.

                    </span>

                `;

            }

        }

    }


    // ======================================================
    // GRAPHIQUE : RÉPARTITION DES ÉTATS MACHINE
    // ======================================================

    function updateMachineStateChart(data) {


        const canvas =
            document.getElementById(
                "machineStateChart"
            );


        if (
            !canvas ||
            typeof Chart === "undefined"
        ) {

            return;

        }


        const stateCounts = {};


        if (Array.isArray(data)) {


            data.forEach(item => {


                const state =
                    (
                        item.etat ||
                        "INCONNU"
                    ).toUpperCase();


                stateCounts[state] =
                    (
                        stateCounts[state] ||
                        0
                    ) + 1;

            });

        }


        const labels =
            Object.keys(
                stateCounts
            );


        const values =
            Object.values(
                stateCounts
            );


        if (machineStateChart) {

            machineStateChart.destroy();

        }


        machineStateChart =
            new Chart(
                canvas,
                {

                    type: "doughnut",


                    data: {

                        labels:
                            labels.length > 0

                                ? labels

                                : ["Aucune donnée"],


                        datasets: [

                            {

                                data:
                                    values.length > 0

                                        ? values

                                        : [1],

                                borderWidth: 2

                            }

                        ]

                    },


                    options: {

                        responsive: true,

                        maintainAspectRatio:
                            false,


                        plugins: {

                            legend: {

                                position:
                                    "bottom"

                            }

                        }

                    }

                }
            );

    }


    // ======================================================
    // GRAPHIQUE : RÉPARTITION DES TYPES D'ALERTES
    // ======================================================

    function updateAlertTypeChart(alerts) {


        const canvas =
            document.getElementById(
                "alertTypeChart"
            );


        if (
            !canvas ||
            typeof Chart === "undefined"
        ) {

            return;

        }


        const alertCounts = {};


        if (Array.isArray(alerts)) {


            alerts.forEach(alert => {


                const type =
                    (
                        alert.type ||
                        "INCONNU"
                    ).toUpperCase();


                alertCounts[type] =
                    (
                        alertCounts[type] ||
                        0
                    ) + 1;

            });

        }


        const labels =
            Object.keys(
                alertCounts
            );


        const values =
            Object.values(
                alertCounts
            );


        if (alertTypeChart) {

            alertTypeChart.destroy();

        }


        alertTypeChart =
            new Chart(
                canvas,
                {

                    type: "bar",


                    data: {

                        labels:
                            labels.length > 0

                                ? labels

                                : ["Aucune alerte"],


                        datasets: [

                            {

                                label:
                                    "Nombre d'alertes",

                                data:
                                    values.length > 0

                                        ? values

                                        : [0],

                                borderWidth: 2

                            }

                        ]

                    },


                    options: {

                        responsive: true,

                        maintainAspectRatio:
                            false,


                        plugins: {

                            legend: {

                                display:
                                    false

                            }

                        },


                        scales: {

                            y: {

                                beginAtZero:
                                    true,

                                ticks: {

                                    precision: 0

                                }

                            }

                        }

                    }

                }
            );

    }
        // ======================================================
    // ÉVÉNEMENTS PAGE ANALYSES
    // ======================================================

    const analyticsMachineFilter =
        document.getElementById(
            "analyticsMachineFilter"
        );


    const targetProductionInput =
        document.getElementById(
            "targetProduction"
        );


    const refreshAnalyticsButton =
        document.getElementById(
            "refreshAnalytics"
        );


    // ======================================================
    // CHANGEMENT DE MACHINE
    // ======================================================

    if (analyticsMachineFilter) {

        analyticsMachineFilter
            .addEventListener(
                "change",
                function () {

                    loadAnalytics();

                }
            );

    }


    // ======================================================
    // CHANGEMENT DE LA PRODUCTION CIBLE
    // ======================================================

    if (targetProductionInput) {

        targetProductionInput
            .addEventListener(
                "change",
                function () {

                    loadAnalytics();

                }
            );

    }


    // ======================================================
    // BOUTON ACTUALISER LES ANALYSES
    // ======================================================

    if (refreshAnalyticsButton) {

        refreshAnalyticsButton
            .addEventListener(
                "click",
                function () {

                    loadAnalytics();

                }
            );

    }


    // ======================================================
    // CHARGEMENT INITIAL DE L'APPLICATION
    // ======================================================

    console.log(
        "Démarrage Dashboard ProdMon..."
    );


    // ------------------------------------------------------
    // Machines
    // ------------------------------------------------------

    loadMachines();


    // ------------------------------------------------------
    // Production et graphiques temps réel
    // ------------------------------------------------------

    loadProduction();


    // ------------------------------------------------------
    // Alertes
    // ------------------------------------------------------

    loadAlerts();


    // ------------------------------------------------------
    // Notifications
    // ------------------------------------------------------

    loadNotifications();


    // ------------------------------------------------------
    // Interventions Maintenance
    // Admin Web = consultation uniquement
    // ------------------------------------------------------

    loadInterventions();


    // ------------------------------------------------------
    // Commandes
    // ------------------------------------------------------

    loadCommands();


    // ------------------------------------------------------
    // Utilisateurs
    // ------------------------------------------------------

    loadUsers();


    // ------------------------------------------------------
    // Analyses / TRS / OEE
    // ------------------------------------------------------

    loadAnalytics();


    console.log(
        "Dashboard ProdMon initialisé."
    );


});
