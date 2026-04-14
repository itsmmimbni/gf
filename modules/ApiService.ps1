function Invoke-GeminiRequest {
    param($url, $chatHistory, $maxTokens)

    $jsonBody = @{ 
        contents = $chatHistory
        generationConfig = @{ 
            maxOutputTokens = $maxTokens
            temperature = 0.7 
        } 
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $url -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) -ContentType "application/json" -UseBasicParsing
    return $response
}