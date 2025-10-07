import basic_demo.ChatClient;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class ChatClientTest {
    private ChatClient chatClient = new ChatClient("localhost", 8080);

    @Test
    void testGetServerPort() {
        int actual = chatClient.getServerPort();
        int expected = 8080;
        assertEquals(expected, actual);
    }
}
