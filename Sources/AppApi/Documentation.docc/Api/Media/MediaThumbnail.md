# Thumbnails

Details about media thumbnails.

## Overview

All media **objects with an image, video or document** also have a thumbnail. For audio objects a thumbnail cannot be provided. 

A thumbnail is always available at the original file name with a trailing `_thumbnail`. All thumbnails are in JPEG format with the file extension `.jpg`.

> Example:
> Original file path: 
> ```
> assets/media/7170030B-8000-4722-9FE1-2DC0F61E5187.pdf
> ``` 
> Thumbnail file path: 
> ```
> assets/media/7170030B-8000-4722-9FE1-2DC0F61E5187_thumbnail.jpg
> ``` 

The **longer side of a thumbnail is no longer than 800 pixels**. This means that all media objects with one side longer than 800 pixels will be scaled down. Additionally, all thumbnails will be compressed, so that their size should usually be **between 10kb and 60kb**. Therefore they are best suited to be quickly loaded and displayed as a preview to the actual media file.  
