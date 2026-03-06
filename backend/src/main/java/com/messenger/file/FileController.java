package com.messenger.file;

import com.messenger.file.dto.FileUploadResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/v1/files")
@Tag(name = "Files", description = "Загрузка файлов (изображения, видео, аудио, PDF)")
public class FileController {

    private final FileService fileService;

    public FileController(FileService fileService) {
        this.fileService = fileService;
    }

    @Operation(summary = "Загрузить файл", description = "Загрузка файла в хранилище. Макс. размер: 100MB. Допустимые типы: JPEG, PNG, GIF, WebP, MP4, WebM, MP3, OGG, PDF.")
    @PostMapping("/upload")
    public ResponseEntity<FileUploadResponse> upload(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(fileService.upload(file));
    }
}
