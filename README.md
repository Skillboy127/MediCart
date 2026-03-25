# MediCart 

MediCart is a modern, offline-first Flutter application designed for managing medicine inventory and facilitating quick checkouts. Built with a sleek dark-mode interface, it offers seamless state management, local storage, and powerful features tailored for pharmacies or personal medical tracking.

DEMO VIDEO - https://youtube.com/shorts/pbymbdlDr80?feature=share

## Features

* **Inventory Management**: Add, edit, and delete medicines with details like Name, Price, and Batch Number.
* **Smart Search**: Instantly find medicines in your inventory with real-time search filtering.
* **Cart & Checkout**: Add items to a shopping cart, adjust quantities, and proceed to checkout smoothly.
* **CSV Integration**: Easily import your existing medicine data from CSV files.
* **Offline First**: Uses Hive for lightning-fast, secure local storage—no internet required.
* **Invoices & History**: Generate receipts, take screenshots, and share them easily. Keep track of your past billing history.
* **Premium UI**: A beautiful, modern dark theme built with Google Fonts (`Inter`) for a great user experience.

## Technology Stack

* **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.4)
* **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
* **Local Database**: [Hive](https://docs.hivedb.dev/) (`hive`, `hive_flutter`)
* **UI/Styling**: `google_fonts`, `cupertino_icons`
* **Utilities**: `csv`, `file_picker`, `path_provider`, `screenshot`, `share_plus`
