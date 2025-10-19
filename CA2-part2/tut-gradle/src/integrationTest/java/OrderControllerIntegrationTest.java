
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import payroll.OrderRepository;
import payroll.Order;
import payroll.Status;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public class OrderControllerIntegrationTest {


    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    private Order testOrder;

    @BeforeEach
    void setUp() {
        orderRepository.deleteAll();

        testOrder = new Order();
        testOrder.setDescription("Test Order");
        testOrder.setStatus(Status.IN_PROGRESS);
        testOrder = orderRepository.save(testOrder);
    }

    @Test
    void cancelOrder_WithInProgressStatus_ShouldCancelSuccessfully() throws Exception {
        mockMvc.perform(delete("/orders/{id}/cancel", testOrder.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"))
                .andExpect(jsonPath("$.description").value("Test Order"))
                .andExpect(jsonPath("$._links.self.href").exists());

        // Verify the order was actually updated in the database
        Order updatedOrder = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals(Status.CANCELLED, updatedOrder.getStatus());
    }
}
