/*
 * This program and the accompanying materials are made available under the terms of the
 * Eclipse Public License v2.0 which accompanies this distribution, and is available at
 * https://www.eclipse.org/legal/epl-v20.html
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Copyright Contributors to the Zowe Project.
 */

package org.zowe.apiml.client.api;

import com.netflix.hystrix.contrib.javanica.annotation.HystrixCommand;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.ServletContext;
import java.io.InputStream;

/**
 * Version 1 of the controller that returns a zip file.
 */
@RestController
@Tag(name = "Other Operations")
public class FileController {
    private final ServletContext servletContext;

    public FileController(ServletContext servletContext) {
        this.servletContext = servletContext;
    }

    @GetMapping(value = "/api/v1/get-file", produces = "image/png")
    @HystrixCommand()
    public ResponseEntity<InputStreamResource> downloadImage() {
        String fileName = "api-catalog.png";
        InputStream inputStream = getClass().getClassLoader().getResourceAsStream(fileName);
        InputStreamResource resource = new InputStreamResource(inputStream);
        String mineType = servletContext.getMimeType(fileName);
        MediaType mediaType = MediaType.parseMediaType(mineType);
        return ResponseEntity.ok()
            .contentType(mediaType)
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename=" + fileName)
            .body(resource);
    }
}
