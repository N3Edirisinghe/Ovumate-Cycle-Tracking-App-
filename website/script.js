// Mobile Menu Toggle
const menuToggle = document.getElementById('menuToggle');
const navMenu = document.querySelector('.nav-menu');

menuToggle.addEventListener('click', () => {
    navMenu.style.display = navMenu.style.display === 'flex' ? 'none' : 'flex';
    navMenu.style.flexDirection = 'column';
    navMenu.style.position = 'absolute';
    navMenu.style.top = '100%';
    navMenu.style.left = '0';
    navMenu.style.width = '100%';
    navMenu.style.background = 'white';
    navMenu.style.padding = '1rem';
    navMenu.style.boxShadow = '0 5px 10px rgba(0, 0, 0, 0.1)';
});

// Smooth Scroll for Navigation Links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
            // Close mobile menu if open
            if (window.innerWidth <= 768) {
                navMenu.style.display = 'none';
            }
        }
    });
});

// Navbar Background on Scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(255, 255, 255, 0.98)';
        navbar.style.backdropFilter = 'blur(15px)';
        navbar.style.boxShadow = '0 4px 25px rgba(0, 0, 0, 0.12)';
    } else {
        navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        navbar.style.backdropFilter = 'blur(10px)';
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.08)';
    }
});

// Intersection Observer for Animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe feature cards
document.querySelectorAll('.feature-card').forEach(card => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(card);
});

// Download Button Click Handler
document.querySelectorAll('.download-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        if (btn.classList.contains('disabled')) {
            e.preventDefault();
            alert('iOS version coming soon!');
        } else if (btn.classList.contains('android')) {
            // Android download - let the browser handle the download
            // The download attribute in HTML will trigger the download
            const apkUrl = btn.getAttribute('href');
            const fileName = btn.getAttribute('download') || 'Ovumate.apk';
            
            // Create a temporary anchor element to trigger download
            const link = document.createElement('a');
            link.href = apkUrl;
            link.download = fileName;
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // Optional: Track download event
            console.log('Android APK download initiated:', fileName);
        } else if (btn.classList.contains('ios')) {
            // iOS download handler
            e.preventDefault();
            const ipaUrl = btn.getAttribute('href');
            const fileName = btn.getAttribute('download') || 'Ovumate.ipa';
            
            // Check if user is on iOS device
            const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
            
            if (isIOS) {
                // For iOS devices, try to open the App Store or TestFlight link
                // You can replace this with your actual App Store or TestFlight URL
                const appStoreUrl = 'https://apps.apple.com/app/ovumate'; // Replace with your App Store URL
                const testFlightUrl = 'https://testflight.apple.com/join/XXXXXX'; // Replace with your TestFlight URL
                
                // Try to open TestFlight first, fallback to App Store
                window.open(testFlightUrl, '_blank') || window.open(appStoreUrl, '_blank');
            } else {
                // For non-iOS devices, download the IPA file
                const link = document.createElement('a');
                link.href = ipaUrl;
                link.download = fileName;
                link.style.display = 'none';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                console.log('iOS IPA download initiated:', fileName);
            }
        } else if (btn.classList.contains('windows')) {
            // Windows download handler
            const zipUrl = btn.getAttribute('href');
            const fileName = btn.getAttribute('download') || 'Ovumate-Windows.zip';
            
            // Create a temporary anchor element to trigger download
            const link = document.createElement('a');
            link.href = zipUrl;
            link.download = fileName;
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // Optional: Track download event
            console.log('Windows ZIP download initiated:', fileName);
        }
    });
});

// Add active state to navigation links
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-menu a');

window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.scrollY >= sectionTop - 200) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
});

// Add CSS for active nav link
const style = document.createElement('style');
style.textContent = `
    .nav-menu a.active {
        color: var(--primary-pink);
        font-weight: 600;
    }
`;
document.head.appendChild(style);

