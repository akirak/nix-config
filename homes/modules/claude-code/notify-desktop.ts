#!/usr/bin/env deno run --allow-run --allow-read

/**
 * Claude Code Desktop Notification Forwarder
 *
 * This script reads JSON notification data from stdin and forwards it
 * to the desktop notification system using notify-desktop.
 */

interface NotificationData {
  session_id: string;
  transcript_path: string;
  message: string;
  title: string;
}

async function main() {
  try {
    // Read JSON data from stdin
    const decoder = new TextDecoder();
    const input = new Uint8Array(4096);
    const bytesRead = await Deno.stdin.read(input);

    if (!bytesRead) {
      console.error("No input received from stdin");
      Deno.exit(1);
    }

    const jsonText = decoder.decode(input.slice(0, bytesRead));
    const data: NotificationData = JSON.parse(jsonText);

    // Validate required fields
    if (!data.title || !data.message) {
      console.error("Missing required fields: title and message");
      Deno.exit(1);
    }

    // Send notification using notify-desktop
    const command = new Deno.Command("notify-desktop", {
      args: [
        "--app-name",
        "Claude Code",
        "--icon",
        "terminal",
        "--urgency",
        "normal",
        data.title,
        data.message,
      ],
      stdout: "piped",
      stderr: "piped",
    });

    const { code, stdout, stderr } = await command.output();

    if (code !== 0) {
      const errorText = new TextDecoder().decode(stderr);
      console.error(`notify-desktop failed with code ${code}: ${errorText}`);
      Deno.exit(code);
    }

    console.log("Notification sent successfully");
  } catch (error) {
    if (error instanceof SyntaxError) {
      console.error("Invalid JSON input:", error.message);
    } else {
      console.error("Error:", error.message);
    }
    Deno.exit(1);
  }
}

if (import.meta.main) {
  await main();
}
