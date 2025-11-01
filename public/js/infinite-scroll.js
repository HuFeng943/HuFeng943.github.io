(() => {
  // <stdin>
  document.addEventListener("DOMContentLoaded", () => {
    let postListContainer = document.getElementById("post-list-container");
    let paginationFooter = document.getElementById("pagination-footer");
    const sentinel = document.getElementById("infinite-scroll-sentinel");
    if (!postListContainer || !paginationFooter || !sentinel) {
      console.log("Infinite scroll elements not found or no pagination.");
      return;
    }
    let isLoading = false;
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !isLoading) {
          const currentNextLinkElement = paginationFooter.querySelector("a.next");
          if (currentNextLinkElement) {
            isLoading = true;
            const nextUrl = currentNextLinkElement.href;
            console.log(`Fetching next page: ${nextUrl}`);
            fetch(nextUrl).then((response) => {
              if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
              }
              return response.text();
            }).then((html) => {
              const parser = new DOMParser();
              const doc = parser.parseFromString(html, "text/html");
              const newArticles = doc.querySelectorAll("#post-list-container article");
              newArticles.forEach((article) => {
                postListContainer.appendChild(article);
              });
              const newNextLinkInDoc = doc.querySelector("#pagination-footer a.next");
              if (newNextLinkInDoc) {
                currentNextLinkElement.href = newNextLinkInDoc.href;
                console.log(`Updated next page link to: ${currentNextLinkElement.href}`);
              } else {
                paginationFooter.style.display = "none";
                observer.disconnect();
                console.log("All pages loaded. Pagination hidden.");
              }
            }).catch((error) => {
              console.error("Error fetching next page:", error);
              if (paginationFooter) {
                paginationFooter.style.display = "none";
              }
              observer.disconnect();
            }).finally(() => {
              isLoading = false;
            });
          } else {
            if (paginationFooter) {
              paginationFooter.style.display = "none";
            }
            observer.disconnect();
            console.log("No more pages to load or initial state.");
          }
        }
      });
    }, {
      root: null,
      // 观察者将观察整个视口
      rootMargin: "0px 0px 200px 0px",
      // 当观察者元素距离底部200px时触发
      threshold: 0.01
      // 只要有一点点进入视口就触发
    });
    observer.observe(sentinel);
  });
})();
