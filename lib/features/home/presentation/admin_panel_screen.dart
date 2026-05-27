import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/laboratory_background.dart';


class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final security = sl<SecurityService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('PANEL DE CONTROL', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: AppTheme.accentColor),
            tooltip: 'Probar Notificación',
            onPressed: () => sl<NotificationService>().triggerTestNotification(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await security.signOut();
              if (context.mounted) {
                Navigator.of(context).pop(); // Volver al dashboard que redirigirá al login
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LaboratoryBackground(
        child: StreamBuilder<QuerySnapshot>(

        stream: security.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay aspirantes registrados.'));
          }

          final users = snapshot.data!.docs;
          
          // Sort locally to handle documents without created_at
          final sortedUsers = users.toList()..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['created_at'] as Timestamp?;
            final bTime = bData['created_at'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedUsers.length,
              itemBuilder: (context, index) {
                final userData = sortedUsers[index].data() as Map<String, dynamic>;
              final email = userData['email'] ?? 'Sin email';
              final name = userData['displayName'] ?? 'Aspirante';
              final isActive = userData['active'] ?? false;
              final deviceId = userData['last_device_id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive 
                      ? Colors.greenAccent.withOpacity(0.3) 
                      : Colors.redAccent.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.greenAccent : Colors.grey,
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(email, style: const TextStyle(fontSize: 12)),
                      if (deviceId != null)
                        Text('ID: $deviceId', 
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Switch(
                    value: isActive,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) => security.toggleUserStatus(email, val),
                  ),
                  onLongPress: () => _showOptions(context, email, security),
                ),
              );
            },
          ),
        );
      },
    ),
  ),
);
}

  void _showOptions(BuildContext context, String email, SecurityService security) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phonelink_erase_rounded, color: Colors.orangeAccent),
              title: const Text('Resetear Dispositivo (Liberar ID)'),
              onTap: () {
                security.resetUserDevice(email);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Eliminar definitivamente'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Eliminar aspirante?'),
                    content: const Text('Esta acción es irreversible y borrará todo el historial del usuario.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );

                if (confirm == true) {
                  await security.deleteUser(email);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
