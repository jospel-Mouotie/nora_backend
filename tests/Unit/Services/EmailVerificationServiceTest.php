<?php

namespace Tests\Unit\Services;

use App\Services\EmailVerificationService;
use PHPUnit\Framework\TestCase;

class EmailVerificationServiceTest extends TestCase
{
    private EmailVerificationService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new EmailVerificationService;
    }

    public function test_generate_code_returns_six_digit_string(): void
    {
        $code = $this->service->generateCode();

        $this->assertIsString($code);
        $this->assertEquals(6, strlen($code));
    }

    public function test_generate_code_is_numeric(): void
    {
        $code = $this->service->generateCode();

        $this->assertTrue(ctype_digit($code));
    }

    public function test_generate_code_is_zero_padded(): void
    {
        // Run multiple times to increase chance of getting a low number
        $allSixDigits = true;
        for ($i = 0; $i < 50; $i++) {
            $code = $this->service->generateCode();
            if (strlen($code) !== 6) {
                $allSixDigits = false;
                break;
            }
        }

        $this->assertTrue($allSixDigits);
    }

    public function test_generate_code_produces_varying_codes(): void
    {
        $codes = [];
        for ($i = 0; $i < 10; $i++) {
            $codes[] = $this->service->generateCode();
        }

        // At least some codes should differ (probabilistically guaranteed)
        $this->assertGreaterThan(1, count(array_unique($codes)));
    }

    public function test_verify_code_returns_true_for_matching_codes(): void
    {
        $result = $this->service->verifyCode('test@example.com', '123456', '123456');

        $this->assertTrue($result);
    }

    public function test_verify_code_returns_false_for_mismatched_codes(): void
    {
        $result = $this->service->verifyCode('test@example.com', '123456', '654321');

        $this->assertFalse($result);
    }

    public function test_verify_code_is_case_sensitive(): void
    {
        $result = $this->service->verifyCode('test@example.com', 'ABCdef', 'abcdef');

        $this->assertFalse($result);
    }

    public function test_verify_code_empty_strings(): void
    {
        $this->assertTrue($this->service->verifyCode('test@example.com', '', ''));
    }

    public function test_verify_code_with_leading_zeros(): void
    {
        $this->assertTrue($this->service->verifyCode('test@example.com', '000001', '000001'));
        $this->assertFalse($this->service->verifyCode('test@example.com', '1', '000001'));
    }
}
