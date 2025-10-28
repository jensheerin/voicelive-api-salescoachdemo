"""Tests for the managers module."""

import tempfile
from datetime import datetime
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import yaml

from src.services.managers import AgentManager, ScenarioManager


class TestScenarioManager:
    """Test scenario manager functionality."""

    def test_scenario_manager_with_nonexistent_directory(self):
        """Test scenario manager with non-existent directory."""
        with tempfile.TemporaryDirectory() as temp_dir:
            non_existent_path = Path(temp_dir) / "nonexistent"
            manager = ScenarioManager(scenario_dir=non_existent_path)
            assert len(manager.scenarios) == 0

    def test_scenario_manager_with_valid_scenarios(self):
        """Test scenario manager loading valid scenarios."""
        with tempfile.TemporaryDirectory() as temp_dir:
            scenario_dir = Path(temp_dir)

            # Create a test scenario file
            scenario_data = {
                "name": "Test Scenario",
                "description": "A test scenario",
                "messages": [{"content": "Test instructions"}],
            }

            scenario_file = scenario_dir / "test-scenario-role-play.prompt.yml"
            with open(scenario_file, "w", encoding="utf-8") as f:
                yaml.safe_dump(scenario_data, f)

            manager = ScenarioManager(scenario_dir=scenario_dir)
            assert len(manager.scenarios) == 1
            assert "test-scenario" in manager.scenarios

    def test_get_scenario_existing(self):
        """Test getting an existing scenario."""
        manager = ScenarioManager()
        manager.scenarios = {"test": {"name": "Test Scenario"}}

        scenario = manager.get_scenario("test")
        assert scenario is not None
        assert scenario["name"] == "Test Scenario"

    def test_get_scenario_nonexistent(self):
        """Test getting a non-existent scenario."""
        manager = ScenarioManager()
        manager.scenarios = {}

        scenario = manager.get_scenario("nonexistent")
        assert scenario is None

    def test_list_scenarios(self):
        """Test listing scenarios."""
        manager = ScenarioManager()
        manager.scenarios = {
            "scenario1": {"name": "Scenario 1", "description": "First scenario"},
            "scenario2": {"name": "Scenario 2", "description": "Second scenario"},
        }

        scenarios = manager.list_scenarios()
        assert len(scenarios) == 3
        assert scenarios[0]["id"] == "scenario1"
        assert scenarios[1]["id"] == "scenario2"
        assert scenarios[2]["id"] == "graph-api"
        assert scenarios[2]["is_graph_scenario"] is True


class TestAgentManager:
    """Test cases for AgentManager."""

    def setup_method(self):
        """Set up test fixtures."""
        with patch("src.services.managers.config") as mock_config:
            mock_config.__getitem__.side_effect = lambda key: {
                "use_azure_ai_agents": False,
                "project_endpoint": "",
                "model_deployment_name": "gpt-4o",
            }.get(key, "")
            mock_config.get.side_effect = lambda key, default=None: {
                "use_azure_ai_agents": False,
                "project_endpoint": "",
                "model_deployment_name": "gpt-4o",
            }.get(key, default)
            with patch("src.services.managers.DefaultAzureCredential"):
                self.agent_manager = AgentManager()  # pylint: disable=attribute-defined-outside-init

    @patch("src.services.managers.config")
    def test_create_agent_success_local(self, mock_config):
        """Test successful local agent creation."""
        # Configure for local agent creation (no Azure AI Agents)
        mock_config.__getitem__.side_effect = lambda key: {
            "use_azure_ai_agents": False,
            "model_deployment_name": "gpt-4o",
        }.get(key, "default")

        manager = AgentManager()
        scenario_data = {
            "messages": [{"content": "Test instructions"}],
            "model": "gpt-4",
            "modelParameters": {"temperature": 0.8, "max_tokens": 1500},
        }

        agent_id = manager.create_agent("test-scenario", scenario_data)

        assert agent_id.startswith("local-agent-test-scenario-")
        assert agent_id in manager.agents
        assert manager.agents[agent_id]["scenario_id"] == "test-scenario"
        assert manager.agents[agent_id]["is_azure_agent"] is False
        assert "Test instructions" in manager.agents[agent_id]["instructions"]
        assert manager.BASE_INSTRUCTIONS in manager.agents[agent_id]["instructions"]

    @patch("src.services.managers.config")
    @patch("src.services.managers.AIProjectClient")
    def test_create_agent_success_azure(self, mock_ai_client, mock_config):
        """Test successful Azure agent creation."""
        # Mock configuration
        mock_config.__getitem__.side_effect = lambda key: {
            "use_azure_ai_agents": True,
            "project_endpoint": "https://test.endpoint",
            "model_deployment_name": "gpt-4o",
        }.get(key, "")
        mock_config.get.side_effect = lambda key, default=None: {
            "use_azure_ai_agents": True,
            "project_endpoint": "https://test.endpoint",
            "model_deployment_name": "gpt-4o",
        }.get(key, default)

        # Mock AI Project Client with context manager support
        mock_client_instance = MagicMock()
        mock_client_instance.__enter__ = Mock(return_value=mock_client_instance)
        mock_client_instance.__exit__ = Mock(return_value=None)

        mock_agent = Mock()
        mock_agent.id = "test-azure-agent-id"
        mock_client_instance.agents.create_agent.return_value = mock_agent
        mock_ai_client.return_value = mock_client_instance

        # Create agent manager with Azure AI enabled
        agent_manager = AgentManager()
        agent_manager.project_client = mock_client_instance

        scenario_data = {
            "messages": [{"content": "Test instructions"}],
            "model": "gpt-4o",
            "modelParameters": {"temperature": 0.8, "max_tokens": 1500},
        }

        agent_id = agent_manager.create_agent("test-scenario", scenario_data)

        assert agent_id == "test-azure-agent-id"
        assert agent_id in agent_manager.agents
        agent_config = agent_manager.agents[agent_id]
        assert agent_config["scenario_id"] == "test-scenario"
        assert agent_config["is_azure_agent"] is True
        assert agent_config["model"] == "gpt-4o"
        assert agent_config["temperature"] == 0.8
        assert agent_config["max_tokens"] == 1500

    def test_get_agent_existing(self):
        """Test getting an existing agent."""
        manager = AgentManager()
        test_agent = {"scenario_id": "test", "instructions": "Test"}
        manager.agents["test-agent"] = test_agent

        agent = manager.get_agent("test-agent")
        assert agent == test_agent

    def test_get_agent_nonexistent(self):
        """Test getting a non-existent agent."""
        manager = AgentManager()

        agent = manager.get_agent("nonexistent")
        assert agent is None

    def test_delete_agent_existing(self):
        """Test deleting an existing agent."""
        manager = AgentManager()
        manager.agents["test-agent"] = {"scenario_id": "test"}

        manager.delete_agent("test-agent")
        assert "test-agent" not in manager.agents

    def test_delete_agent_nonexistent(self):
        """Test deleting a non-existent agent (should not raise error)."""
        manager = AgentManager()

        # Should not raise an exception
        manager.delete_agent("nonexistent")
        assert len(manager.agents) == 0

    @patch("src.services.managers.config")
    def test_delete_agent_local(self, mock_config):
        """Test deleting a local agent."""
        mock_config.__getitem__.side_effect = lambda key: {
            "use_azure_ai_agents": False,
            "model_deployment_name": "gpt-4o",
        }.get(key, "default")

        manager = AgentManager()
        manager.agents["test-agent"] = {"scenario_id": "test", "is_azure_agent": False}

        manager.delete_agent("test-agent")
        assert "test-agent" not in manager.agents

    @patch("src.services.managers.config")
    @patch("src.services.managers.AIProjectClient")
    def test_delete_agent_azure(self, mock_ai_client, mock_config):
        """Test Azure agent deletion."""
        # Mock configuration
        mock_config.__getitem__.side_effect = lambda key: {
            "use_azure_ai_agents": True,
            "project_endpoint": "https://test.endpoint",
            "model_deployment_name": "gpt-4o",
        }.get(key, "")
        mock_config.get.side_effect = lambda key, default=None: {
            "use_azure_ai_agents": True,
            "project_endpoint": "https://test.endpoint",
            "model_deployment_name": "gpt-4o",
        }.get(key, default)

        # Mock AI Project Client with context manager support
        mock_client_instance = MagicMock()
        mock_client_instance.__enter__ = Mock(return_value=mock_client_instance)
        mock_client_instance.__exit__ = Mock(return_value=None)
        mock_ai_client.return_value = mock_client_instance

        # Create agent manager
        agent_manager = AgentManager()
        agent_manager.project_client = mock_client_instance

        # Add a test Azure agent
        agent_id = "test-azure-agent"
        agent_manager.agents[agent_id] = {
            "scenario_id": "test-scenario",
            "is_azure_agent": True,
            "instructions": "Test instructions",
            "created_at": datetime.now(),
            "model": "gpt-4o",
            "temperature": 0.7,
            "max_tokens": 2000,
            "azure_agent_id": agent_id,
        }

        # Delete the agent
        agent_manager.delete_agent(agent_id)

        # Verify deletion
        assert agent_id not in agent_manager.agents
        mock_client_instance.agents.delete_agent.assert_called_once_with(agent_id)
        agent_manager.delete_agent(agent_id)

        # Verify deletion
        assert agent_id not in agent_manager.agents
        mock_client_instance.agents.delete_agent.assert_called_once_with(agent_id)
