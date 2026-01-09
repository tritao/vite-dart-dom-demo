---
title: InputOTP
slug: input-otp
group: Forms
order: 7
description: One-time password input.
status: beta
tags: [forms, ui]
---

An OTP input splits a code across multiple inputs with paste support.

By default it accepts digits only (non-digit characters are ignored). Use `allowedChar` if you need alphanumeric codes.

:::demo id=input-otp-basic title="Basic InputOTP"
Type digits, use Backspace to move, or paste a full code.
:::

:::code file=src/docs/examples/input_otp_basic.dart region=snippet lang=dart
:::

:::props name=InputOTP
:::
