import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatimestories/src/models/order.dart';
import '../services/order_service.dart';

// ✅ Updated with "Completed"
const List<String> orderStatuses = [
  'Pending',
  'Preparing',
  'Ready',
  'Picked Up',
  'Completed',
];

// ✅ Updated color mapping for "Completed"
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'preparing':
      return Colors.amber;
    case 'ready':
      return Colors.lightBlue;
    case 'picked up':
      return Colors.green;
    case 'completed':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

class OrderTile extends StatefulWidget {
  final Order order;
  final bool isAdmin;

  const OrderTile({
    super.key,
    required this.order,
    this.isAdmin = false,
  });

  @override
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    try {
      await Provider.of<OrderService>(context, listen: false)
          .updateOrderStatus(widget.order.id, newStatus);
      setState(() {
        _currentStatus = newStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        tileColor: getStatusColor(_currentStatus).withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text('Order #${widget.order.id} - ${widget.order.customerName}'),

        // ✅ Fixed: Using Wrap to avoid overflow
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(_currentStatus).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentStatus,
                style: TextStyle(
                  color: getStatusColor(_currentStatus),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Total: ₹${widget.order.total.toStringAsFixed(2)}'),
          ],
        ),

        trailing: _isUpdating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : SizedBox(
          width: 120,
          child: DropdownButton<String>(
            isDense: true,
            value: _currentStatus,
            items: orderStatuses
                .map((status) => DropdownMenuItem(
              value: status,
              child: Text(status),
            ))
                .toList(),
            onChanged: (!widget.isAdmin || _isUpdating)
                ? null
                : (newStatus) {
              if (newStatus != null && newStatus != _currentStatus) {
                _updateStatus(newStatus);
              }
            },
          ),
        ),
      ),
    );
  }
}

