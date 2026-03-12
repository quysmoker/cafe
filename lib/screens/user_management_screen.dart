import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'create_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text(
          'Quản lý nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen()),
          ).then((_) {
            // reload lại danh sách khi quay về
            context.read<AdminProvider>().loadUsers();
          });
        },
      ),

      body: admin.loading
          ? const Center(child: CircularProgressIndicator())
          : admin.users.isEmpty
          ? const Center(
              child: Text(
                'Chưa có nhân viên',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: admin.users.length,
              itemBuilder: (_, i) {
                final u = admin.users[i];
                final isSelf = u['username'] == auth.username;

                final isAdmin = u['role'] == 'admin';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? Colors.orange.shade200
                          : Colors.lightBlue.shade200,
                      child: Icon(
                        isAdmin ? Icons.security : Icons.person,
                        color: Colors.white,
                      ),
                    ),

                    title: Text(
                      u['username'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      isAdmin ? 'Admin' : 'Nhân viên',
                      style: TextStyle(
                        color: isAdmin ? Colors.orange : Colors.grey.shade700,
                      ),
                    ),

                    trailing: isSelf
                        ? const Chip(
                            label: Text('Bạn'),
                            backgroundColor: Colors.lightBlueAccent,
                          )
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (v) async {
                              if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xoá nhân viên'),
                                    content: Text(
                                      'Bạn có chắc muốn xoá tài khoản "${u['username']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Huỷ'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Xoá'),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok == true) {
                                  await admin.deleteUser(u['id']);
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Xoá'),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }
}
