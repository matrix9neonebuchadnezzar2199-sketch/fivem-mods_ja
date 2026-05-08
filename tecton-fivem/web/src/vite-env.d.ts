// SPDX-License-Identifier: LGPL-3.0-or-later

/// <reference types="vite/client" />

declare module '*.module.css' {
  const classes: { readonly [key: string]: string }
  export default classes
}
