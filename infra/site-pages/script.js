
document.addEventListener("DOMContentLoaded", () => {
    console.log("Cloud Portfolio carregado!");

    const message = document.getElementById("message");

    if (message) {
        const now = new Date();

        message.textContent =
            `Site carregado com sucesso! Horário local: ${now.toLocaleTimeString("pt-BR")}`;
    }
});
