// Check if the current page is the home page based on the URL
if (window.location.pathname === '/') {
    // Remove element with class .md-nav__item--active
    var activeNavItem = document.querySelector('.md-nav__item--active');
  
    if (activeNavItem) {
      activeNavItem.parentNode.removeChild(activeNavItem);
      // Alternatively, you can hide the element by changing its style
      // activeNavItem.style.display = 'none';
    }
  
    // Remove first h1 element inside .md-content__inner
    var contentInner = document.querySelector('.md-content__inner');
    if (contentInner) {
      var firstH1 = contentInner.querySelector('h1:nth-child(1)');
      if (firstH1) {
        firstH1.parentNode.removeChild(firstH1);
        // Alternatively, you can hide the element by changing its style
        // firstH1.style.display = 'none';
      }
    }
  }
  