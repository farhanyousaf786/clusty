import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildNotificationItem(String name, String message, String time, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          radius: 25,
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(message),
        trailing: Text(
          time,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: theme.iconTheme.color),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '5',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              color: theme.colorScheme.background,
              padding: EdgeInsets.only(bottom: 10),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorColor: Colors.transparent,
                labelColor: theme.textTheme.bodyLarge!.color,
                unselectedLabelColor: theme.textTheme.bodyMedium!.color,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite, color: theme.iconTheme.color),
                          SizedBox(width: 8),
                          Text('Kudos'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment, color: theme.iconTheme.color),
                          SizedBox(width: 8),
                          Text('Comments'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildNotificationItem('Michael Drek', 'Kudos your activity!', 'just now', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Jessyka Swan', 'Kudos your activity!', 'just now', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Bruno Mars', 'Kudos your activity!', '2 hours', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Christopher J.', 'Kudos your activity!', '7 hours', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Jin Yang', 'Kudos your activity!', '2 days', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Anis Mosal', 'Kudos your activity!', '3 days', 'https://via.placeholder.com/150'),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildNotificationItem('Michael Drek', 'Commented on your post!', 'just now', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Jessyka Swan', 'Commented on your post!', 'just now', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Bruno Mars', 'Commented on your post!', '2 hours', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Christopher J.', 'Commented on your post!', '7 hours', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Jin Yang', 'Commented on your post!', '2 days', 'https://via.placeholder.com/150'),
              _buildNotificationItem('Anis Mosal', 'Commented on your post!', '3 days', 'https://via.placeholder.com/150'),
            ],
          ),
        ],
      ),
    );
  }
}
