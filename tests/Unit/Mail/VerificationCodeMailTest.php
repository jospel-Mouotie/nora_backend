<?php

namespace Tests\Unit\Mail;

use App\Mail\VerificationCodeMail;
use PHPUnit\Framework\TestCase;

class VerificationCodeMailTest extends TestCase
{
    public function test_constructor_sets_code_and_name(): void
    {
        $mail = new VerificationCodeMail('123456', 'John Doe');

        $this->assertEquals('123456', $mail->code);
        $this->assertEquals('John Doe', $mail->name);
    }

    public function test_content_uses_correct_view(): void
    {
        $mail = new VerificationCodeMail('111111', 'Test User');
        $content = $mail->content();

        $this->assertEquals('emails.verification_code', $content->view);
    }

    public function test_content_passes_code_and_name(): void
    {
        $mail = new VerificationCodeMail('999999', 'Alice');
        $content = $mail->content();

        $this->assertArrayHasKey('code', $content->with);
        $this->assertArrayHasKey('name', $content->with);
        $this->assertEquals('999999', $content->with['code']);
        $this->assertEquals('Alice', $content->with['name']);
    }

    public function test_attachments_returns_empty_array(): void
    {
        $mail = new VerificationCodeMail('000000', 'Test');

        $this->assertEquals([], $mail->attachments());
    }
}
