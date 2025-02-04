/*
 * This program and the accompanying materials are made available under the terms of the
 * Eclipse Public License v2.0 which accompanies this distribution, and is available at
 * https://www.eclipse.org/legal/epl-v20.html
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Copyright Contributors to the Zowe Project.
 */

package org.zowe.apiml.client.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.zowe.apiml.client.model.state.New;

import javax.validation.constraints.NotNull;

/**
 * This model is used for integration test of PageRedirectionFilter.java
 * It wraps Location url
 */
@Schema
@Data
public class RedirectLocation {

    @NotNull(groups = New.class, message = "Location should not be null")
    @Schema(description = "Redirect location", example = "https://hostA:8080/some/path")
    private String location;

    public RedirectLocation(@JsonProperty("location") String location) {
        this.location = location;
    }
}
