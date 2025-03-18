# Car Rental App UI Design Guide

This document outlines the UI design system for the Car Rental App, providing guidelines for maintaining a consistent user interface across all screens.

## Color Palette

The app uses a consistent color palette defined in `lib/core/theme/app_theme.dart`:

- **Primary Colors**
  - Primary: `#1E88E5` (Blue 600)
  - Primary Dark: `#1565C0` (Blue 800)
  - Primary Light: `#64B5F6` (Blue 300)
  - Accent: `#FF9800` (Orange 500)

- **Background Colors**
  - Background: `#F5F5F5` (Grey 100)
  - Card: `#FFFFFF` (White)
  - Scaffold Background: `#FFFFFF` (White)

- **Text Colors**
  - Text Primary: `#212121` (Grey 900)
  - Text Secondary: `#757575` (Grey 600)
  - Text Light: `#BDBDBD` (Grey 400)

- **Status Colors**
  - Success: `#4CAF50` (Green 500)
  - Error: `#F44336` (Red 500)
  - Warning: `#FFEB3B` (Yellow 500)
  - Info: `#2196F3` (Blue 500)

## Typography

The app uses a consistent typography system defined in the theme:

- **Display Styles**
  - Display Large: 32px, Bold
  - Display Medium: 28px, Bold
  - Display Small: 24px, Bold

- **Headline Styles**
  - Headline Large: 22px, SemiBold
  - Headline Medium: 20px, SemiBold
  - Headline Small: 18px, SemiBold

- **Title Styles**
  - Title Large: 16px, SemiBold
  - Title Medium: 14px, SemiBold
  - Title Small: 12px, SemiBold

- **Body Styles**
  - Body Large: 16px, Regular
  - Body Medium: 14px, Regular
  - Body Small: 12px, Regular

- **Label Styles**
  - Label Large: 14px, Medium
  - Label Medium: 12px, Medium
  - Label Small: 10px, Medium

## Common UI Components

The app uses a set of common UI components defined in `lib/core/widgets/common_widgets.dart`:

### App Bars

1. **CommonAppBar**
   - Standard app bar with consistent styling
   - Used for most screens

2. **LocationAppBar**
   - Special app bar with location display
   - Used in the Cars page

### Navigation

**CustomBottomNavigationBar**
- Consistent bottom navigation with 3 tabs: Cars, History, Profile
- Used in the HomeScreen

### Cards and Containers

**AppCard**
- Consistent card styling with rounded corners and elevation
- Used for displaying information blocks

### Buttons

**AppButton**
- Consistent button styling with options for outlined or filled
- Supports icons and full-width options

### Text Fields

**AppTextField**
- Consistent text field styling
- Supports various input types and validation

### Search

**AppSearchBar**
- Specialized search field with filter button
- Used in the Cars page

### Section Headers

**SectionTitle**
- Consistent section title with optional trailing widget
- Used to separate content sections

### Empty States

**EmptyState**
- Consistent empty state display with icon and message
- Optional action button

### Loading States

**LoadingIndicator**
- Consistent loading indicator with optional message
- Used during data fetching

### User Information

**UserGreeting**
- Consistent user greeting with name and optional subtitle
- Used in the Cars page

## Screen Structure

Each screen should follow a consistent structure:

1. **App Bar**: Use either CommonAppBar or LocationAppBar
2. **Content Area**: Wrapped in a ScrollView with consistent padding (AppUI.padding)
3. **Section Headers**: Use SectionTitle for content sections
4. **Cards**: Use AppCard for information blocks
5. **Loading States**: Use LoadingIndicator during data fetching
6. **Empty States**: Use EmptyState when no data is available

## Spacing and Layout

The app uses consistent spacing defined in AppUI:

- **Padding**
  - Standard: 16px all sides
  - Horizontal: 16px left/right
  - Vertical: 16px top/bottom

- **Spacing**
  - Small: 8px
  - Standard: 16px
  - Large: 24px

- **Border Radius**
  - Small: 4px
  - Standard: 8px
  - Large: 16px

## Implementation Guidelines

When implementing new screens or modifying existing ones:

1. Import the common widgets and theme:
   ```dart
   import 'package:carrentalapp/core/widgets/common_widgets.dart';
   import 'package:carrentalapp/core/theme/app_theme.dart';
   ```

2. Use the theme colors and text styles:
   ```dart
   color: AppColors.primary,
   style: Theme.of(context).textTheme.headlineMedium,
   ```

3. Use the common widgets for consistent UI:
   ```dart
   appBar: CommonAppBar(title: 'Screen Title'),
   ```

4. Use consistent padding and spacing:
   ```dart
   padding: AppUI.padding,
   SizedBox(height: AppUI.spacing),
   ```

By following these guidelines, we ensure a consistent and professional user interface throughout the app. 