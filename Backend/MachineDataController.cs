using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProdMonApi.Data;
using ProdMonApi.Models;
using ProdMonApi.Services;

namespace ProdMonApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MachineDataController : ControllerBase
{
    private readonly ProdMonDbContext _context;
    private readonly EmailService _emailService;

    public MachineDataController(
        ProdMonDbContext context,
        EmailService emailService)
    {
        _context = context;
        _emailService = emailService;
    }

    // GET: api/MachineData
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var data = await _context.MachineData
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        return Ok(data);
    }

    // GET: api/MachineData/machine/1
    [HttpGet("machine/{machineId:int}")]
    public async Task<IActionResult> GetByMachine(int machineId)
    {
        var data = await _context.MachineData
            .Where(d => d.MachineId == machineId)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        return Ok(data);
    }

    // POST: api/MachineData
    [HttpPost]
    public async Task<IActionResult> Create(MachineData machineData)
    {
        // Vérifier que la machine existe
        var machine = await _context.Machines
            .FirstOrDefaultAsync(m => m.Id == machineData.MachineId);

        if (machine == null)
        {
            return BadRequest(new
            {
                message = "Machine introuvable."
            });
        }

        // Enregistrement des données machine
        machineData.CreatedAt = DateTime.UtcNow;

        _context.MachineData.Add(machineData);

        // Mise à jour du statut actuel de la machine
        machine.Statut = machineData.Etat;

        await _context.SaveChangesAsync();

        // =================================================
        // DÉTECTION AUTOMATIQUE DES PROBLÈMES
        // =================================================

        string? typeAlerte = null;
        string? messageAlerte = null;

        // 1. Demande d'aide opérateur
        if (machineData.DemandeAide)
        {
            typeAlerte = "DEMANDE_AIDE";

            messageAlerte =
                $"Une demande d'assistance a été envoyée depuis {machine.Nom}.";
        }

        // 2. Température élevée
        else if (machineData.Temperature.HasValue &&
                 machineData.Temperature.Value >= 70)
        {
            typeAlerte = "TEMPERATURE_ELEVEE";

            messageAlerte =
                $"Température élevée détectée sur {machine.Nom} : " +
                $"{machineData.Temperature.Value} °C.";
        }

        // 3. Machine arrêtée
        else if (machineData.Etat == "STOPPED")
        {
            typeAlerte = "ARRET_MACHINE";

            messageAlerte =
                $"{machine.Nom} est actuellement arrêtée.";
        }

        // =================================================
        // CRÉATION DE L'ALERTE
        // =================================================

        if (typeAlerte != null && messageAlerte != null)
        {
            var alert = new Alert
            {
                MachineId = machineData.MachineId,
                Type = typeAlerte,
                Message = messageAlerte,
                Statut = "ACTIVE",
                DateHeure = DateTime.UtcNow
            };

            _context.Alerts.Add(alert);

            await _context.SaveChangesAsync();

            // =================================================
            // RECHERCHE DE L'ADMINISTRATEUR
            // =================================================

            var admin = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Role == "Admin" &&
                    u.IsActive);

            if (admin != null)
            {
                try
                {
                    // =================================================
                    // ENVOI DE L'E-MAIL
                    // =================================================

                    await _emailService.SendEmailAsync(
                        admin.Email,
                        $"Alerte ProdMon - {machine.Nom}",
                        $"""
                        <h2 style="color:#d32f2f;">
                            Alerte ProdMon
                        </h2>

                        <p>
                            Un événement nécessitant votre attention
                            a été détecté.
                        </p>

                        <hr>

                        <p>
                            <strong>Machine :</strong>
                            {machine.Nom}
                        </p>

                        <p>
                            <strong>Localisation :</strong>
                            {machine.Localisation}
                        </p>

                        <p>
                            <strong>Type d'alerte :</strong>
                            {typeAlerte}
                        </p>

                        <p>
                            <strong>État :</strong>
                            {machineData.Etat}
                        </p>

                        <p>
                            <strong>Température :</strong>
                            {machineData.Temperature} °C
                        </p>

                        <p>
                            <strong>Production :</strong>
                            {machineData.Production}
                        </p>

                        <p>
                            <strong>Message :</strong>
                            {messageAlerte}
                        </p>

                        <hr>

                        <p>
                            Une vérification de la machine est recommandée.
                        </p>

                        <p>
                            Équipe ProdMon
                        </p>
                        """
                    );

                    // =================================================
                    // HISTORIQUE DE NOTIFICATION
                    // =================================================

                    var notification = new Notification
                    {
                        AlertId = alert.Id,
                        Destinataire = admin.Email,
                        Canal = "EMAIL",
                        Statut = "ENVOYEE",
                        DateEnvoi = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Notifications.Add(notification);

                    await _context.SaveChangesAsync();
                }
                catch (Exception)
                {
                    // Si l'email échoue, garder une trace dans PostgreSQL
                    var notification = new Notification
                    {
                        AlertId = alert.Id,
                        Destinataire = admin.Email,
                        Canal = "EMAIL",
                        Statut = "ECHEC",
                        DateEnvoi = null,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Notifications.Add(notification);

                    await _context.SaveChangesAsync();
                }
            }
        }

        return CreatedAtAction(
            nameof(GetByMachine),
            new
            {
                machineId = machineData.MachineId
            },
            machineData
        );
    }
}
