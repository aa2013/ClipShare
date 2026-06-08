part of '../clip_list_view.dart';

extension _ClipListBody on ClipListViewState {
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        return Future.delayed(
          500.ms,
          widget.onRefreshData,
        );
      },
      child: ConditionWidget(
        visible: widget.list.isEmpty,
        replacement: LayoutBuilder(
          builder: (ctx, constraints) {
            final isImageMode = widget.imageMasonryGridViewLayout;
            final maxWidth = isImageMode ? 200.0 : 395;
            final showMore =
                (appConfig.showMoreItemsInRow && !appConfig.isSmallScreen) ||
                    isImageMode;
            final count =
                showMore ? max(2, constraints.maxWidth ~/ maxWidth) : 1;
            return Listener(
              child: MasonryGridView.count(
                crossAxisCount: count,
                mainAxisSpacing: 4,
                shrinkWrap: true,
                itemCount: widget.list.length,
                controller: _scrollController,
                physics: _scrollPhysics,
                itemBuilder: (context, index) {
                  if (isImageMode) {
                    return renderItem(index);
                  } else {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                      constraints: const BoxConstraints(
                        maxHeight: 150,
                        minHeight: 80,
                      ),
                      child: renderItem(index),
                    );
                  }
                },
              ),
              onPointerSignal: (e) {
                if (e is PointerScrollEvent) {
                  if (_scrollController.position.pixels ==
                      _scrollController.position.maxScrollExtent) {
                    Log.debug(tag, "Try loading more data at the bottom");
                    _loadMoreData();
                  }
                }
              },
            );
          },
        ),
        child: Stack(
          children: [
            ListView(),
            EmptyContent(),
          ],
        ),
      ),
    );
  }
}
