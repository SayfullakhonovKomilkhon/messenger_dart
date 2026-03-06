package com.messenger.file.dto;

public record FileUploadResponse(
        String fileId,
        String fileUrl,
        String mimeType,
        long size
) {}
