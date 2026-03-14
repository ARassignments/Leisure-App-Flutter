import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '/Models/slider_image_model.dart';
import '/theme/theme.dart';

class DashboardSlider extends StatefulWidget {
  const DashboardSlider({super.key});

  @override
  State<DashboardSlider> createState() => _DashboardSliderState();
}

class _DashboardSliderState extends State<DashboardSlider> {
  bool _isLoading = false;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  final List<SliderImageModel> sliderImages = [
    SliderImageModel(
      url:
          'https://plus.unsplash.com/premium_photo-1663931932651-ea743c9a0144?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1470',
      isDartWatermark: true,
    ),
    SliderImageModel(
      url:
          'https://images.unsplash.com/photo-1643101681441-0c38d714fa14?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1332',
      isDartWatermark: true,
    ),
    SliderImageModel(
      url:
          'https://plus.unsplash.com/premium_photo-1663931932688-306b0197d388?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1pbi1zYW1lLXNlcmllc3wxfHx8ZW58MHx8fHx8&auto=format&fit=crop&q=60&w=500',
      isDartWatermark: false,
    ),
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _isLoading ? _buildShimmerPlaceholder() : _buildImageCarousel(context),
        const SizedBox(height: 12),
        if (!_isLoading) _buildSmoothIndicator(context),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 🟣 Shimmer Placeholder
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppTheme.customListBg(context),
      highlightColor: AppTheme.sliderHighlightBg(context),
      child: CarouselSlider.builder(
        itemCount: 1,
        itemBuilder: (context, index, realIndex) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.customListBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
        options: CarouselOptions(
          height: 200,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
        ),
      ),
    );
  }

  /// 🟢 Actual Carousel
  Widget _buildImageCarousel(BuildContext context) {
    return CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: sliderImages.length,
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(sliderImages[index].url),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  sliderImages[index].isDartWatermark
                      ? "assets/images/logo_dark.png"
                      : "assets/images/logo.png",
                  width: 80,
                ),
              ),
            ],
          ),
        );
      },
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        clipBehavior: Clip.antiAlias,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        viewportFraction: 0.9,
        autoPlayInterval: const Duration(seconds: 3),
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// 🔵 SmoothPageIndicator
  Widget _buildSmoothIndicator(BuildContext context) {
    return AnimatedSmoothIndicator(
      activeIndex: _currentIndex,
      count: sliderImages.length,
      effect: CustomizableEffect(
        spacing: 8,
        activeDotDecoration: DotDecoration(
          width: 24,
          height: 8,
          color: AppTheme.onBoardingDotActive(context),
          borderRadius: BorderRadius.circular(4),
        ),
        dotDecoration: DotDecoration(
          width: 8,
          height: 8,
          color: AppTheme.onBoardingDot(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onDotClicked: (index) {
        _carouselController.animateToPage(index);
      },
    );
  }
}
