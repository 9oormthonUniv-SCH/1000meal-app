import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/store_view_model.dart';
import '../widgets/store_section.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드 (최초 1회)
    Future.microtask(() {
      Provider.of<StoreViewModel>(context, listen: false).loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "오늘의 천밥",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StoreViewModel>().refreshStores();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        // 당겨서 새로고침 기능
        onRefresh: () async {
          await context.read<StoreViewModel>().refreshStores();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 내용이 적어도 스크롤 가능하게
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 안내 문구 등 (필요 시 추가)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "현재 운영 중인 식당 목록입니다.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              // 여기가 핵심! 아까 만든 StoreSection을 그대로 가져옵니다.
              const StoreSection(),

              const SizedBox(height: 50), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}
