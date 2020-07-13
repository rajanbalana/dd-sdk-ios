/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

internal struct RUMEventFileOutput: RUMEventOutput {
   let fileWriter: FileWriter

   func write<DM: RUMDataModel>(rumEvent: RUMEvent<DM>) {
       fileWriter.write(value: rumEvent)
   }
}
