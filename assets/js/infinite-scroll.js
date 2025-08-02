// assets/js/infinite-scroll.js

document.addEventListener('DOMContentLoaded', () => {
    // 获取文章列表容器
    let postListContainer = document.getElementById('post-list-container');
    // 获取分页导航的footer
    let paginationFooter = document.getElementById('pagination-footer');
    // 获取观察者元素
    const sentinel = document.getElementById('infinite-scroll-sentinel');

    // 如果这些元素不存在，或者没有分页，就直接退出
    if (!postListContainer || !paginationFooter || !sentinel) {
        console.log('Infinite scroll elements not found or no pagination.');
        return;
    }

    let isLoading = false; // 标记是否正在加载，防止重复触发

    // 创建Intersection Observer实例
    const observer = new IntersectionObserver(entries => {
        // 遍历所有被观察的元素
        entries.forEach(entry => {
            // 如果观察者元素进入视口，并且当前没有正在加载
            if (entry.isIntersecting && !isLoading) {
                const currentNextLinkElement = paginationFooter.querySelector('a.next'); // 获取当前页面上的“下一页”链接元素

                if (currentNextLinkElement) {
                    isLoading = true; // 设置加载中状态
                    const nextUrl = currentNextLinkElement.href; // 获取下一页的URL

                    console.log(`Fetching next page: ${nextUrl}`);

                    // 发送AJAX请求获取下一页内容
                    fetch(nextUrl)
                        .then(response => {
                            if (!response.ok) {
                                throw new Error(`HTTP error! status: ${response.status}`);
                            }
                            return response.text();
                        })
                        .then(html => {
                            // 解析获取到的HTML内容
                            const parser = new DOMParser();
                            const doc = parser.parseFromString(html, 'text/html');

                            // 从新页面中提取文章列表
                            const newArticles = doc.querySelectorAll('#post-list-container article');
                            
                            // 将新文章追加到当前页面
                            newArticles.forEach(article => {
                                postListContainer.appendChild(article);
                            });

                            // 检查新加载的页面中是否还有下一页链接
                            const newNextLinkInDoc = doc.querySelector('#pagination-footer a.next');

                            if (newNextLinkInDoc) {
                                // 如果新页面有下一页链接，更新当前页面上“下一页”按钮的href
                                currentNextLinkElement.href = newNextLinkInDoc.href;
                                console.log(`Updated next page link to: ${currentNextLinkElement.href}`);
                            } else {
                                // 如果新页面没有下一页链接，说明已经到最后一页了
                                paginationFooter.style.display = 'none'; // 隐藏分页导航
                                observer.disconnect(); // 停止观察，因为没有更多内容了
                                console.log('All pages loaded. Pagination hidden.');
                            }
                        })
                        .catch(error => {
                            console.error('Error fetching next page:', error);
                            // 发生错误时也隐藏分页，避免用户一直等待
                            if (paginationFooter) {
                                paginationFooter.style.display = 'none';
                            }
                            observer.disconnect();
                        })
                        .finally(() => {
                            isLoading = false; // 无论成功失败，都解除加载中状态
                        });
                } else {
                    // 初始就没有下一页链接，或者已经加载到最后一页
                    if (paginationFooter) {
                        paginationFooter.style.display = 'none'; // 隐藏分页导航
                    }
                    observer.disconnect(); // 停止观察
                    console.log('No more pages to load or initial state.');
                }
            }
        });
    }, {
        root: null, // 观察者将观察整个视口
        rootMargin: '0px 0px 200px 0px', // 当观察者元素距离底部200px时触发
        threshold: 0.01 // 只要有一点点进入视口就触发
    });

    // 开始观察sentinel元素
    observer.observe(sentinel);
});
