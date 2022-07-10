# file_system_access

This package contains the bindings for the [File System Access web API](https://developer.mozilla.org/docs/Web/API/File_System_Access_API) implemented for some browsers.

# Functionalities

You can view the [demo](https://juancastillo0.github.io/file_system_access_web/) for the main functionalities in this package. The main source code for the demo can be found in the [example/main.dart](https://github.com/juancastillo0/file_system_access_web/blob/main/example/lib/main.dart) file.

You can also view the main exposed API from this package in the [interface file](https://github.com/juancastillo0/file_system_access_web/blob/main/lib/src/file_system_access_interface.dart).

Most APIs work for all platforms, desktop and mobile though `dart:io` and web with JavaScript bindings. One notable exception is `getPersistence` which is only implemented in web, since it would be easier to save the path of the file or directory along with any other data in native (non-web) platforms.

The `FileSystem.instance.isSupported` bool is true when the APIs implemented in this package are available in the user's device.

## Files

With `showOpenFilePicker` you can ask the user to select files from the local file system. You can pass the extensions (.png, .pdf) that the files selected by the user should have. This will return the list of `FileSystemFileHandle`s to the user.

The `getFile` method in `FileSystemFileHandle` allows you to read the file contents and other information (last updated date, mime type, path on native platforms).

### Permissions

With the `queryPermission` and `requestPermission` methods in a `FileSystemHandle` you can query and request "read" and "readwrite" permission to the user. This is available for directories and files.

In some browsers, the user may need to interact with the application first before you can request permissions. A "Security Error" will be thrown, the [demo](https://juancastillo0.github.io/file_system_access_web/) application shows it when you select something and refresh the page.

### Write to files

With the `createWritable` method in a `FileSystemFileHandle` (that has "readwrite" permissions), you can edit the contents of the file.

### `showSaveFilePicker`

This asks the user to select a file name and location for a new file which will have "readwrite" permissions. In this way, you can modify it and save it in the selected file system location.

## Directories

The `showDirectoryPicker` function asks the user to select a directory. The selected directory will have "read" permissions.

You can use the `entries` method for retrieving all the items inside the directory or the `getFileHandle` and `getDirectoryHandle` using the name of each item.

The `resolve` method retuns a List of Strings with the path to the `FileSystemHandle` passed as argument or `null` if it is not a child of the directory.

### Create and delete files

With a `FileSystemDirectoryHandle`, that has "readwrite" permissions, you can create files or directories using the `getFileHandle(create: true)` and `getDirectoryHandle(create: true)`. You can delete them with `removeEntry`.


## Directory Synchronizer

The `DirectorySynchronizer` class allows you to sync an in-memory and editable directory abstraction with the persisted one in the user's machine.


## Persistence with `getPersistence`

The `FileSystemPersistance` returned by `getPersistence` allows you to save a `FileSystemHandle` in the browser's IndexedDB. This is useful for maintaining the application state between sessions inside the browser.

This API is only available in web, you could save the path String in native platforms.

### Usage

For Flutter, you will need to add the `assets/file_persistence.js` file to your assets in your `pubspec.yaml`:

```yaml
  assets:
    - packages/file_system_access/assets/file_persistence.js
```

And then import it in you HTML:

```html
<script src="./assets/packages/file_system_access/assets/file_persistence.js"></script>
```

For Dart web projects, you will need to import "./packages/file_system_access/assets/file_persistence.js" instead (without the first "assets" path).

The [demo](https://juancastillo0.github.io/file_system_access_web/) shows an example usage.

# File System Access API documentation

In the following links you can find more about the API spec and documentation

MDN:
https://developer.mozilla.org/docs/Web/API/File_System_Access_API

GitHub:
https://github.com/WICG/file-system-access

Article:
https://web.dev/file-system-access/

Web Platform Incubator Community Group - W3C:
https://wicg.github.io/file-system-access/

TypeScript definitions:
https://www.npmjs.com/package/@types/wicg-file-system-access





