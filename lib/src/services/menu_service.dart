import '../config/supabase.dart';
import '../models/menu_item.dart';

class MenuService {
  Future<List<MenuItem>> fetchMenu() async {
    try {
      final response = await SupabaseConfig.client
          .from('menu_items')
          .select()
          .execute();

      final data = response.data as List<dynamic>?;

      if (data == null) {
        return [];
      }

      return data.cast<Map<String, dynamic>>().map((item) => MenuItem.fromJson(item)).toList();
    } catch (e) {
      // Optionally log error
      // print('Fetch menu error: $e');
      return [];
    }
  }

  Future<void> addMenuItem(MenuItem item) async {
    try {
      await SupabaseConfig.client.from('menu_items').insert(item.toJson()).execute();
    } catch (e) {
      // Handle error or rethrow
      // print('Add menu item error: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await SupabaseConfig.client
          .from('menu_items')
          .update(item.toJson())
          .eq('id', item.id)
          .execute();
    } catch (e) {
      // print('Update menu item error: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await SupabaseConfig.client.from('menu_items').delete().eq('id', id).execute();
    } catch (e) {
      // print('Delete menu item error: $e');
      rethrow;
    }
  }
}
